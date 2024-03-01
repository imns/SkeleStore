//
//  File.swift
//
//
//  Created by Nate Smith on 3/1/24.
//

import Foundation
import SQLite3

internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public enum StorageType {
    /// In-memory storage. Not persisted between application launches.
    /// Good for unit testing or caching.
    case memory

    /// File-based storage, persisted between application launches.
    case file(path: String)
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public actor SQLiteEngine {
    /// An opaque handle to a SQLite connection.
    typealias ConnectionHandle = OpaquePointer
    typealias StatementHandle = OpaquePointer

    var db: ConnectionHandle?

    public func open(storage: StorageType = .memory) async throws {
        let path: String
        switch storage {
        case .memory:
            path = ":memory:"
        case .file(let file):
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(file)
            path = fileURL.path
        }

        if sqlite3_open(path, &db) != SQLITE_OK {
            throw SQLiteError(reason: .cantOpen, message: "Error opening database.")
        }
    }

    func setupDatabase() async throws {
        if db == nil {
            throw SQLiteError(reason: .connection, message:
                "You must open the database connection before calling `setupDatabase()`")
        }

        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS documents (
            id TEXT PRIMARY KEY,
            body TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        // TODO: Should these be wrapped in a transaction?
        try await execute(sql: createTableSQL, binds: [])
        try await execute(sql: "PRAGMA journal_mode = WAL")
        try await execute(sql: "PRAGMA synchronous = NORMAL")
        try await execute(sql: "PRAGMA foreign_keys = ON")
    }

    func createIndexes() async throws {
        let createIndexSQL = "CREATE INDEX IF NOT EXISTS idx_document_id ON documents (json_extract(body, '$.id'));"
        try await execute(sql: createIndexSQL, binds: [])
    }

    private func bind(_ stmt: StatementHandle?, binds: [SQLiteData]) throws {
        for (i, bind) in binds.enumerated() {
            let index = Int32(i + 1)
            switch bind {
//            case .blob(let value):
//                if sqlite3_bind_blob(stmt, index, (value as NSData).bytes, Int32(value.count), SQLITE_TRANSIENT) != SQLITE_OK {
//                    throw SQLiteError(message: "Error binding blob")
//                }
            case .blob(let data):
                try data.withUnsafeBytes { bytes in
                    // Ensure there's a base address to work with; otherwise, it's an error condition.
                    guard let ptr = bytes.baseAddress else {
                        throw SQLiteError(reason: .format, message: "Error accessing blob data bytes")
                    }

                    // sqlite3_bind_blob expects a non-optional pointer, so we pass ptr assuming it's non-nil after the guard check.
                    let result = sqlite3_bind_blob(stmt, index, ptr, Int32(data.count), SQLITE_TRANSIENT)

                    // Check the result of sqlite3_bind_blob and throw if not successful.
                    guard result == SQLITE_OK else {
                        throw SQLiteError(reason: .format, message: "Error binding blob")
                    }
                }

            case .float(let value):
                if sqlite3_bind_double(stmt, index, value) != SQLITE_OK {
                    throw SQLiteError(reason: .format, message: "Error binding float")
                }
            case .integer(let value):
                if sqlite3_bind_int64(stmt, index, Int64(value)) != SQLITE_OK {
                    throw SQLiteError(reason: .format, message: "Error binding integer")
                }
            case .null:
                if sqlite3_bind_null(stmt, index) != SQLITE_OK {
                    throw SQLiteError(reason: .format, message: "Error binding null")
                }
            case .text(let value):
                if sqlite3_bind_text(stmt, index, value, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                    throw SQLiteError(reason: .format, message: "Error binding text")
                }
            }
        }
    }

    func execute(sql: String, binds: [SQLiteData] = []) async throws {
        enum DatabaseError: Error {
            case prepareStatementError(String)
            case bindError(String)
            case executionError(String)
            case unknownError
        }
        var stmt: OpaquePointer?

        // Prepare statement
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareStatementError("PreparedStatement Error: \(errorMessage)")
        }

        defer {
            sqlite3_finalize(stmt)
        }

        // Bind parameters
        do {
            try bind(stmt, binds: binds)
        } catch {
            // Convert any error during binding into a DatabaseError
            throw DatabaseError.bindError("Error binding parameters: \(error.localizedDescription)")
        }

        // Execute statement
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.executionError("Error executing statement: \(errorMessage)")
        }
    }

    // Async version of query
    func query(_ query: String, binds: [SQLiteData] = []) async throws -> [[SQLiteData]] {
        var results: [[SQLiteData]] = []
        var stmt: OpaquePointer?

        // Prepare the statement
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw SQLiteError(reason: .prepare, message: "PreparedStatement Error: \(errorMessage)")
        }

        defer {
            sqlite3_finalize(stmt)
        }

        // Bind parameters to the statement
        do {
            try bind(stmt, binds: binds)
        } catch {
            throw SQLiteError(reason: .format, message: "Error binding parameters: \(error.localizedDescription)")
        }

        // Execute the query and construct the result
        while sqlite3_step(stmt) == SQLITE_ROW {
            let columnsCount = sqlite3_column_count(stmt)
            var row: [SQLiteData] = []

            for columnIndex in 0 ..< columnsCount {
//                TODO: This should be used to cast the response data
//                let columnType = sqlite3_column_type(stmt, columnIndex)
                let sqliteValue = sqlite3_column_value(stmt, columnIndex)
                if let sqliteValue = sqliteValue {
                    do {
                        let value = try SQLiteData(sqliteValue: sqliteValue)
                        row.append(value)
                    } catch {
                        // Handle the error for unexpected value types, like blobs that are not yet implemented
                        throw error
                    }
                } else {
                    // Handle unexpected null values gracefully
                    row.append(.null)
                }
            }

            results.append(row)
        }

        return results
    }

    /// Closes the database connection.
    func close() throws {
        if sqlite3_close(db) != SQLITE_OK {
            throw SQLiteError(reason: .close, message: "Error closing database.")
        }
        db = nil
    }

    deinit {
        Task {
            try await close()
        }
    }
}

@available(macOS 10.15, *)
extension SQLiteEngine {
    func checkSQLiteVersion() -> String? {
        if let version = sqlite3_libversion() {
            let versionString = String(cString: version)
            print("SQLite version: \(versionString)")
            return versionString
        }
        return nil
    }
}

@available(macOS 10.15, *)
public extension SQLiteEngine {
    /// Supported SQLite data types.
    enum SQLiteData: Equatable, Encodable, CustomStringConvertible {
        /// `Int`.
        case integer(Int)

        /// `Double`.
        case float(Double)

        /// `String`.
        case text(String)

        /// `ByteBuffer`.
        case blob(Data)

        /// `NULL`.
        case null

        public var integer: Int? {
            switch self {
            case .integer(let integer):
                return integer
            case .float(let double):
                return Int(double)
            case .text(let string):
                return Int(string)
            case .blob, .null:
                return nil
            }
        }

        public var double: Double? {
            switch self {
            case .integer(let integer):
                return Double(integer)
            case .float(let double):
                return double
            case .text(let string):
                return Double(string)
            case .blob, .null:
                return nil
            }
        }

        public var string: String? {
            switch self {
            case .integer(let integer):
                return String(integer)
            case .float(let double):
                return String(double)
            case .text(let string):
                return string
            case .blob, .null:
                return nil
            }
        }

        public var bool: Bool? {
            switch integer {
            case 1: return true
            case 0: return false
            default: return nil
            }
        }

        public var isNull: Bool {
            switch self {
            case .null:
                return true
            case .integer, .float, .text, .blob:
                return false
            }
        }

        /// Description of data
        public var description: String {
            switch self {
            case .blob(let data): return "<\(data.description) bytes>"
            case .float(let float): return float.description
            case .integer(let int): return int.description
            case .null: return "null"
            case .text(let text): return "\"" + text + "\""
            }
        }

        /// See `Encodable`.
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .integer(let value): try container.encode(value)
            case .float(let value): try container.encode(value)
            case .text(let value): try container.encode(value)
            case .blob(let value): try container.encode(value)
            case .null: try container.encodeNil()
            }
        }

        init(sqliteValue: OpaquePointer) throws {
            switch sqlite3_value_type(sqliteValue) {
            case SQLITE_NULL:
                self = .null
            case SQLITE_INTEGER:
                self = .integer(Int(sqlite3_value_int64(sqliteValue)))
            case SQLITE_FLOAT:
                self = .float(sqlite3_value_double(sqliteValue))
            case SQLITE_TEXT:
                self = .text(String(cString: sqlite3_value_text(sqliteValue)!))
            case SQLITE_BLOB:
                let size = sqlite3_value_bytes(sqliteValue)
                if let bytes = sqlite3_value_blob(sqliteValue) {
                    self = .blob(Data(bytes: bytes, count: Int(size)))
                } else {
                    self = .null // TODO: how to handle null blobs?
                }
            case let type:
                throw SQLiteCustomFunctionUnexpectedValueTypeError(type: type)
            }
        }
    }

    struct SQLiteCustomFunctionUnexpectedValueTypeError: Error {
        let type: Int32
    }
}

@available(macOS 10.15, *)
extension SQLiteEngine.SQLiteData: Sendable {}
