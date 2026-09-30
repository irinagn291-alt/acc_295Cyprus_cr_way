import Foundation

/// Role: DropMark. Missed seat. The lifted canvas returns to Waiting. Saved keeps the miss reviewable.
struct DropMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var rampinID: UUID
    var field: CartelField
    var cartelText: String
    var daykey: Int
}
