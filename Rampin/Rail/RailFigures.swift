import Foundation

/// Role: Rail. Hook counts, drop counts, and daykeys go through NumberFormatter. Views never interpolate a raw Int.
enum RailFigures {
    static func count(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func daykey(_ value: Int) -> String {
        dayLabel(value)
    }

    static func dayLabel(_ value: Int) -> String {
        var parts = DateComponents()
        parts.year = value / 10_000
        parts.month = (value / 100) % 100
        parts.day = value % 100
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
