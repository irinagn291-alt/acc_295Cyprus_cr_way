import AppIntents
import Foundation

/// Role: Rail. App Intents open Quiz, Explore, Saved, or Settings, or fire spreadRail, liftWork, or hookRampin in place.
struct OpenQuizIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Quiz" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        RailPost.broadcast(.quiz)
        return .result()
    }
}

struct OpenExploreIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Explore" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        RailPost.broadcast(.explore)
        return .result()
    }
}

struct OpenSavedIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Saved" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        RailPost.broadcast(.saved)
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Settings" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        RailPost.broadcast(.settings)
        return .result()
    }
}

struct SpreadRailIntent: AppIntent {
    static var title: LocalizedStringResource { "Spread the rail" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        RailPost.broadcast(.spread)
        return .result()
    }
}

struct LiftWorkIntent: AppIntent {
    static var title: LocalizedStringResource { "Lift a canvas" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        RailPost.broadcast(.lift)
        return .result()
    }
}

struct HookRampinIntent: AppIntent {
    static var title: LocalizedStringResource { "Hook a nameplate" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        RailPost.broadcast(.hook)
        return .result()
    }
}

struct RampinShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenQuizIntent(),
            phrases: [
                "Open Quiz in \(.applicationName)",
                "Hook the rail in \(.applicationName)",
            ],
            shortTitle: "Quiz",
            systemImageName: "rectangle.portrait"
        )
        AppShortcut(
            intent: OpenExploreIntent(),
            phrases: [
                "Open Explore in \(.applicationName)",
            ],
            shortTitle: "Explore",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: OpenSavedIntent(),
            phrases: [
                "Open Saved in \(.applicationName)",
            ],
            shortTitle: "Saved",
            systemImageName: "bookmark"
        )
        AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open Settings in \(.applicationName)",
            ],
            shortTitle: "Settings",
            systemImageName: "gearshape"
        )
        AppShortcut(
            intent: SpreadRailIntent(),
            phrases: [
                "Spread the rail in \(.applicationName)",
            ],
            shortTitle: "Spread",
            systemImageName: "square.grid.3x1.below.line.grid.1x2"
        )
        AppShortcut(
            intent: LiftWorkIntent(),
            phrases: [
                "Lift a canvas in \(.applicationName)",
            ],
            shortTitle: "Lift",
            systemImageName: "arrow.up.to.line"
        )
        AppShortcut(
            intent: HookRampinIntent(),
            phrases: [
                "Hook this nameplate in \(.applicationName)",
            ],
            shortTitle: "Hook",
            systemImageName: "checkmark.circle"
        )
    }
}
