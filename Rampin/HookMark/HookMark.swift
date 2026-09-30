import Foundation

/// Role: HookMark. True seat. The lifted Work matched that Rampin's Cartel and folded to Hooked. The third HookMark Settles the rail.
struct HookMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var rampinID: UUID
    var field: CartelField
    var cartelText: String
    var daykey: Int
}
