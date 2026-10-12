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
    var note: String?

    var id: String { objectID }

    var studyNote: String? {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    enum CodingKeys: String, CodingKey {
        case objectID
        case artist
        case title
        case imageURLString
        case dated
        case note
    }

    init(objectID: String, artist: String, title: String, imageURLString: String?, dated: String?, note: String? = nil) {
        self.objectID = objectID
        self.artist = artist
        self.title = title
        self.imageURLString = imageURLString
        self.dated = dated
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        objectID = try container.decode(String.self, forKey: .objectID)
        artist = try container.decode(String.self, forKey: .artist)
        title = try container.decode(String.self, forKey: .title)
        imageURLString = try container.decodeIfPresent(String.self, forKey: .imageURLString)
        dated = try container.decodeIfPresent(String.self, forKey: .dated)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(objectID, forKey: .objectID)
        try container.encode(artist, forKey: .artist)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(imageURLString, forKey: .imageURLString)
        try container.encodeIfPresent(dated, forKey: .dated)
        try container.encodeIfPresent(note, forKey: .note)
    }

    var imageURL: URL? {
        CatalogClient.thumbURL(from: imageURLString)
    }
}
