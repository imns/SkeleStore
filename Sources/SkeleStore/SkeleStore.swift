//// The Swift Programming Language
//// https://docs.swift.org/swift-book
//
// import Foundation
//
// public enum StorageType {
//    /// In-memory storage. Not persisted between application launches.
//    /// Good for unit testing or caching.
//    case memory
//
//    /// File-based storage, persisted between application launches.
//    case file(path: String)
// }
//
// @available(macOS 10.15, *)
// public protocol SQLiteEngine: Actor {
//    /// An opaque handle to a SQLite connection.
//    typealias ConnectionHandle = OpaquePointer
//    typealias StatementHandle = OpaquePointer
//
//    var db: ConnectionHandle? { get set }
//
//    func open(storage: StorageType) async throws
//    func execute(sql: String, binds: [SQLiteData]) async throws
//    func query(_ query: String, binds: [SQLiteData]) async throws -> [[SQLiteData]]
//    func close()
// }
//
// public struct Document<T> {
//    var id: UUID
//    var body: T
//
//    init(id: UUID = UUID(), body: T) {
//        self.id = id
//        self.body = body
//    }
// }
//
// @available(macOS 10.15, *)
// public actor DocumentStoreAdapter {
//    private let storage: SQLiteEngine
//
//    init(storage: SQLiteEngine) {
//        self.storage = storage
//    }
//
//    /// Uses the storage engine to query the database, and return a single document
//    public func getById<T>(id: UUID) async throws -> Document<T>? {
//        do {
//            let result = try await storage.query("select * from TABLE where id = ?", binds: [.text(id.uuidString)])
//            // TODO: do stuff to transfor result into T
//
//            // return T or nil
//            return nil
//        } catch {
//            // TODO: wrap this error
//            throw error
//        }
//    }
//    // public func create(... ?) async throws -> Bool
//    // public func update(id: UUID) async throws -> Bool
//    // public func delete(id: UUID) async throws -> Bool
// }
//
// public enum SQLiteData: Equatable, Encodable, CustomStringConvertible {
//    /// `Int`.
//    case integer(Int)
//
//    /// `Double`.
//    case float(Double)
//
//    /// `String`.
//    case text(String)
//
//    /// `ByteBuffer`.
//    case blob(Data)
//
//    /// `NULL`.
//    case null
//
//    public var integer: Int? {
//        switch self {
//        case .integer(let integer):
//            return integer
//        case .float(let double):
//            return Int(double)
//        case .text(let string):
//            return Int(string)
//        case .blob, .null:
//            return nil
//        }
//    }
//
//    public var double: Double? {
//        switch self {
//        case .integer(let integer):
//            return Double(integer)
//        case .float(let double):
//            return double
//        case .text(let string):
//            return Double(string)
//        case .blob, .null:
//            return nil
//        }
//    }
//
//    public var string: String? {
//        switch self {
//        case .integer(let integer):
//            return String(integer)
//        case .float(let double):
//            return String(double)
//        case .text(let string):
//            return string
//        case .blob, .null:
//            return nil
//        }
//    }
//
//    public var bool: Bool? {
//        switch integer {
//        case 1: return true
//        case 0: return false
//        default: return nil
//        }
//    }
//
//    public var isNull: Bool {
//        switch self {
//        case .null:
//            return true
//        case .integer, .float, .text, .blob:
//            return false
//        }
//    }
//
//    /// Description of data
//    public var description: String {
//        switch self {
//        case .blob(let data): return "<\(data.description) bytes>"
//        case .float(let float): return float.description
//        case .integer(let int): return int.description
//        case .null: return "null"
//        case .text(let text): return "\"" + text + "\""
//        }
//    }
// }
