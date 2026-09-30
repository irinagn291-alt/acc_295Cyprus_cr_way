import Foundation

/// Role: Work. Bundled Philadelphia Museum of Art shelf. Empty or failed search hangs from here. Not a food catalog.
struct PmaShelf: Sendable {
    var rows: [CatalogRow]

    static let bundled = PmaShelf(rows: Self.makeRows())

    private static func makeRows() -> [CatalogRow] {
        [
            row(
                "Q773861",
                "Thomas Eakins",
                "The Gross Clinic",
                "1875",
                "Thomas Eakins, American - Portrait of Dr. Samuel D. Gross (The Gross Clinic) - Google Art Project.jpg"
            ),
            row(
                "Q698518",
                "Marcel Duchamp",
                "Nude Descending a Staircase No. 2",
                "1912",
                "Duchamp - Nude Descending a Staircase.jpg"
            ),
            row(
                "Q7756187",
                "Edward Hicks",
                "The Peaceable Kingdom",
                "1834",
                "Edward Hicks - Peaceable Kingdom.jpg"
            ),
            row(
                "Q3399414",
                "Peter Paul Rubens",
                "Prometheus Bound",
                "1618",
                "Peter Paul Rubens - Prometheus Bound - Google Art Project.jpg"
            ),
            row(
                "Q18749255",
                "Henry Ossawa Tanner",
                "The Annunciation",
                "1898",
                "Henry Ossawa Tanner - The Annunciation - 1898.jpg"
            ),
            row(
                "Q20487081",
                "Mary Cassatt",
                "Woman with a Pearl Necklace in a Loge",
                "1879",
                "Mary Cassatt - Woman with a Pearl Necklace in a Loge - Google Art Project.jpg"
            ),
            row(
                "Q7720394",
                "Joseph Mallord William Turner",
                "The Burning of the Houses of Lords and Commons",
                "1835",
                "Joseph Mallord William Turner - The Burning of the Houses of Lords and Commons, October 16, 1834 - Google Art Project.jpg"
            ),
            row(
                "Q7714255",
                "Charles Willson Peale",
                "The Artist in His Museum",
                "1822",
                "Charles Willson Peale - The Artist in His Museum - Google Art Project.jpg"
            ),
        ]
    }

    private static func row(
        _ objectID: String,
        _ artist: String,
        _ title: String,
        _ dated: String,
        _ filename: String
    ) -> CatalogRow {
        CatalogRow(
            objectID: objectID,
            artist: artist,
            title: title,
            imageURLString: CatalogClient.commonsFilePath(filename),
            dated: dated
        )
    }
}
