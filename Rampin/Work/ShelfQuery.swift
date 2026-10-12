import Foundation

/// Role: Work. Local cuts of the shelf. Not a second catalog and not a network call.
enum ShelfCut: String, CaseIterable, Identifiable, Sendable {
    case all
    case fresh
    case before1700
    case century1700
    case century1800
    case century1900

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return RailCopy.filterAll
        case .fresh: return RailCopy.filterFresh
        case .before1700: return RailCopy.filterBefore
        case .century1700: return RailCopy.filter1700
        case .century1800: return RailCopy.filter1800
        case .century1900: return RailCopy.filter1900
        }
    }
}

/// Role: Work. Order of one cut. Shelf order is the bundled order.
enum ShelfOrder: String, CaseIterable, Sendable {
    case shelf
    case year
    case maker

    var title: String {
        switch self {
        case .shelf: return RailCopy.orderShelf
        case .year: return RailCopy.orderYear
        case .maker: return RailCopy.orderMaker
        }
    }

    var next: ShelfOrder {
        switch self {
        case .shelf: return .year
        case .year: return .maker
        case .maker: return .shelf
        }
    }
}

enum ShelfQuery {
    static func year(of dated: String?) -> Int? {
        guard let dated else { return nil }
        let digits = dated.prefix(while: \.isNumber)
        guard digits.count == 4, let year = Int(digits) else { return nil }
        return year
    }

    static func apply(
        rows: [CatalogRow],
        cut: ShelfCut,
        order: ShelfOrder,
        saved: Set<String>
    ) -> [CatalogRow] {
        let filtered = rows.filter { row in
            switch cut {
            case .all:
                return true
            case .fresh:
                return !saved.contains(row.objectID)
            case .before1700:
                return (year(of: row.dated) ?? 9_999) < 1_700
            case .century1700:
                guard let year = year(of: row.dated) else { return false }
                return year >= 1_700 && year < 1_800
            case .century1800:
                guard let year = year(of: row.dated) else { return false }
                return year >= 1_800 && year < 1_900
            case .century1900:
                guard let year = year(of: row.dated) else { return false }
                return year >= 1_900 && year < 2_000
            }
        }
        switch order {
        case .shelf:
            return filtered
        case .year:
            return filtered.sorted { lhs, rhs in
                let left = year(of: lhs.dated) ?? Int.max
                let right = year(of: rhs.dated) ?? Int.max
                if left != right { return left < right }
                return lhs.title < rhs.title
            }
        case .maker:
            return filtered.sorted { lhs, rhs in
                let compared = lhs.artist.localizedStandardCompare(rhs.artist)
                if compared != .orderedSame { return compared == .orderedAscending }
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
        }
    }
}
