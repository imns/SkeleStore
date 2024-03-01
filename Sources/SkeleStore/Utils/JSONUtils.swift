import Foundation

struct JSONUtils {
    static func encode<T: DocumentStorable>(document: T) throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(document)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            
            throw NSError(domain: "SkeleStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Encoding to JSON string failed."])
        }
        return jsonString
    }

    static func decode<T: DocumentStorable>(jsonString: String, to type: T.Type) throws -> T {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "SkeleStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Decoding JSON string failed."])
        }
        let decoder = JSONDecoder()
        let document = try decoder.decode(type, from: data)
        return document
    }
}
