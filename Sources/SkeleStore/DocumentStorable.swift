import Foundation

protocol DocumentStorable: Codable, Equatable {
    var id: String { get }
}

/// Default Equatable conformance
extension DocumentStorable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
