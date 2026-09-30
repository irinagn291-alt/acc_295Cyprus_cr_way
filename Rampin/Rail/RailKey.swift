import Foundation

/// Role: Rail. Preference keys. Snapshot is JSON Data under rmp.rail.v1. Demo is Simulator-only.
enum RailKey {
    static let snapshot = "rmp.rail.v1"
    static let backup = "rmp.rail.v1.backup"
    static let demo = "rmp.demo.v1"
}

enum RailCodecError: Error, Equatable, Sendable {
    case unsupportedSchema(Int)
    case corrupt
}
