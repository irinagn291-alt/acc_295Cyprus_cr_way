import Foundation

/// Role: Cartel. Shared field for one spread. Artist XOR title. Never both on the same trio.
enum CartelField: String, Equatable, Sendable, Codable {
    case artist
    case title

    var toggled: CartelField {
        switch self {
        case .artist: return .title
        case .title: return .artist
        }
    }
}

/// Role: Cartel. Nameplate text worn by one Rampin. The field is shared across the planted trio.
struct Cartel: Equatable, Sendable, Codable {
    var field: CartelField
    var text: String

    func names(_ work: Work) -> Bool {
        work.cartelText(for: field) == text
    }
}
