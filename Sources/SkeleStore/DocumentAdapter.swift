import Foundation

@available(iOS 13.0, macOS 10.15, *)
protocol Storable {
    associatedtype Document: Codable
    var storage: SQLiteEngine { get }

    func save(document: Document) async throws
    func fetch(withID id: String) async throws -> Document?
    func update(document: Document) async throws
    func delete(withID id: String) async throws
}

@available(iOS 13.0, macOS 10.15, *)
public actor DocumentAdapter<T: Codable & Identifiable>: Storable {
    typealias Document = T

    let storage: SQLiteEngine = Store.shared.storageEngine

    public init(storage: SQLiteEngine) {
        self.storage = storage
    }

    func save(document: T) async throws {
        let jsonData = try JSONEncoder().encode(document)
        let jsonString = String(decoding: jsonData, as: UTF8.self)
        let sql = "INSERT INTO documents (body) VALUES json(?);"
//        let sql = "INSERT INTO documents VALUES(json(?));"
        try await storage.execute(sql: sql, binds: [.text(jsonString)])
    }

    func fetch(withID id: String) async throws -> T? {
        let sql = "SELECT body FROM documents WHERE json_extract(body, '$.id') = ?;"
        let results = try await storage.query(sql, binds: [.text(id)])
        guard let firstRow = results.first else {
            return nil
        }
        // Assuming `firstRow` is an array of `SQLiteData`
        guard case let .text(jsonString) = firstRow[0] else {
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    func fetchAll() async throws -> [T] {
        let sql = "SELECT body FROM documents;"
        let results = try await storage.query(sql, binds: [])
        return try results.compactMap { row in
            guard case let .text(jsonString) = row[0] else { return nil }
            guard let jsonData = jsonString.data(using: .utf8) else { return nil }
            return try JSONDecoder().decode(T.self, from: jsonData)
        }
    }

    func update(document: T) async throws {
        let jsonData = try JSONEncoder().encode(document)
        let jsonString = String(decoding: jsonData, as: UTF8.self)
        let sql = "UPDATE documents SET body = json(?) WHERE id = ?;"
        try await storage.execute(sql: sql, binds: [.text(jsonString), .text("\(document.id)")])
    }

    func delete(withID id: String) async throws {
        let sql = "DELETE FROM documents WHERE json_extract(body, '$.id') = ?;"
        try await storage.execute(sql: sql, binds: [.text(id)])
    }
}
