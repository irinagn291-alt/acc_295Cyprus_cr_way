import Foundation

/// Role: Rail. Jobs for App Intents and rampin:// plus https://rampin-hook.pro paths. Quiz stays put. No Game tab.
enum RailJob: String, Equatable, Sendable {
    case quiz
    case explore
    case saved
    case settings
    case spread
    case lift
    case hook
    case twist

    static let httpsHost = "rampin-hook.pro"
    static let scheme = "rampin"

    static func parse(_ url: URL) -> RailJob? {
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == Self.scheme {
            let host = url.host?.lowercased() ?? ""
            let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let token = host.isEmpty ? path : host
            return RailJob(rawValue: token)
        }
        if scheme == "https", url.host?.lowercased() == httpsHost {
            let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if path.isEmpty { return .quiz }
            if path == "contact-us" { return .settings }
            return RailJob(rawValue: path)
        }
        return nil
    }

    static func parse(notification: Notification) -> RailJob? {
        guard let raw = notification.userInfo?[RailPost.key] as? String else { return nil }
        return RailJob(rawValue: raw)
    }

    var cover: RailCover? {
        switch self {
        case .quiz, .spread, .lift, .hook:
            return nil
        case .explore:
            return .explore
        case .saved:
            return .saved
        case .settings:
            return .settings
        case .twist:
            return .twist
        }
    }
}

/// Role: Rail. Sheets over the locked Quiz. Four destinations plus the spread-then-hook page.
enum RailCover: String, Identifiable, Equatable, Sendable, CaseIterable {
    case explore
    case saved
    case settings
    case twist

    var id: String { rawValue }
}

extension Notification.Name {
    static let railJob = Notification.Name("rmp.rail.job")
}

enum RailPost {
    static let key = "job"

    static func broadcast(_ job: RailJob) {
        NotificationCenter.default.post(
            name: .railJob,
            object: nil,
            userInfo: [key: job.rawValue]
        )
    }
}
