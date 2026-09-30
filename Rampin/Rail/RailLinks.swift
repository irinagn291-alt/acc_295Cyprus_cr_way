import Foundation

/// Role: Rail. Four destinations as rail-locked sheets. Never a Game tab. ReviewScreen keys are not tabs.
enum RailSheet: String, Equatable, Sendable, CaseIterable {
    case quiz
    case explore
    case saved
    case settings
}

/// Role: Rail. Launch keys for live shots. today, log, and goals open three different screens. Extra key explore.
enum ReviewHook: String, Equatable, Sendable {
    case today
    case log
    case goals
    case explore

    var sheet: RailSheet {
        switch self {
        case .today: return .quiz
        case .log: return .saved
        case .goals: return .settings
        case .explore: return .explore
        }
    }
}

/// Role: Rail. Reads ProcessInfo `-ReviewScreen today|log|goals|explore` once after onboarding. No View.
enum RailLinks {
    static let flag = "-ReviewScreen"

    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> ReviewHook? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return ReviewHook(rawValue: arguments[next])
    }
}
