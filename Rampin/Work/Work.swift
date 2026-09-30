import Foundation

/// Role: Work. Seat of one saved painting on the rail. Waiting, Hooked, or Settled. A parallel settled bool is a defect.
enum WorkSeat: String, Equatable, Sendable, Codable {
    case waiting
    case hooked
    case settled

    var isSettled: Bool { self == .settled }
    var isWaiting: Bool { self == .waiting }
    var isHooked: Bool { self == .hooked }
}

/// Role: Work. Saved Philadelphia Museum of Art accession with maker, title, Commons image, daykey Int YYYYMMDD, and stored seat.
struct Work: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var objectID: String
    var artist: String
    var title: String
    var imageURLString: String?
    var dated: String?
    var daykey: Int
    var seat: WorkSeat

    var imageURL: URL? {
        CatalogClient.thumbURL(from: imageURLString)
    }

    static func waiting(
        from row: CatalogRow,
        id: UUID = UUID(),
        daykey: Int
    ) -> Work {
        Work(
            id: id,
            objectID: row.objectID,
            artist: row.artist,
            title: row.title,
            imageURLString: row.imageURLString,
            dated: row.dated,
            daykey: daykey,
            seat: .waiting
        )
    }

    func cartelText(for field: CartelField) -> String {
        switch field {
        case .artist:
            return artist
        case .title:
            return title
        }
    }
}

/// Role: Work. Catalog row before it is written Waiting. Cached so empty or failed PMA search still hooks from the local shelf.
struct CatalogRow: Identifiable, Equatable, Sendable, Codable {
    var objectID: String
    var artist: String
    var title: String
    var imageURLString: String?
    var dated: String?

    var id: String { objectID }

    var imageURL: URL? {
        CatalogClient.thumbURL(from: imageURLString)
    }
}
