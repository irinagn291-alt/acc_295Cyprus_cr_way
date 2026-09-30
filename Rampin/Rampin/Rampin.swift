import Foundation

/// Role: Rampin. Planted nameplate on the hook rail. Wears one Cartel. This is the quiz card. A fourth fold case does not live here.
struct Rampin: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var cartel: Cartel
    var isStruck: Bool

    func names(_ work: Work) -> Bool {
        work.id == workID && cartel.names(work)
    }
}
