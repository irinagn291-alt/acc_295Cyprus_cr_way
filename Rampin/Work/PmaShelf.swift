import Foundation

/// Role: Work. Bundled Philadelphia Museum of Art shelf. Empty or failed search hangs from here. Not a food catalog.
struct PmaShelf: Sendable {
    var rows: [CatalogRow]

    static let bundled = PmaShelf(rows: Self.makeRows())

    func note(for objectID: String) -> String? {
        rows.first { $0.objectID == objectID }?.studyNote
    }

    static func note(for objectID: String) -> String? {
        bundled.note(for: objectID)
    }

    static func studyText(for objectID: String) -> String? {
        let note = bundled.note(for: objectID)
        let more = further[objectID]
        switch (note, more) {
        case let (note?, more?):
            return note + " " + more
        case let (note?, nil):
            return note
        case let (nil, more?):
            return more
        default:
            return nil
        }
    }

    /// Second sentence for Study. The row keeps the shorter note.
    private static let further: [String: String] = [
        "Q773861": "Dr. Samuel D. Gross leads the operation while students watch from the stands.",
        "Q698518": "The figure is repeated down the stairs so motion stays inside one canvas.",
        "Q7756187": "Hicks painted this subject many times. This canvas keeps the animals and the children together.",
        "Q3399414": "The chain and the eagle are the whole event. The sky stays dark behind them.",
        "Q18749255": "Mary sits in an ordinary room. The light, not a crowd of angels, carries the visit.",
        "Q20487081": "The sitter is in a theater box, turned toward the room rather than the stage.",
        "Q7720394": "Turner watched the Houses of Parliament burn on 16 October 1834 and painted the fire from across the river.",
        "Q7714255": "Peale stands in his museum and lifts a curtain on the cases behind him.",
        "Q18683906": "Monet painted the poplars along the Epte in a row, then the trees were cut.",
        "Q18683915": "Ships sit in the harbor. The light on the water is the subject as much as the hulls.",
        "Q18683923": "The footbridge crosses the lily pool at Giverny. The water holds the reflection.",
        "Q18685520": "Church sets the volcano Pichincha over a wide green valley.",
        "Q18685714": "Seurat builds the boats and the trees from small touches of color.",
        "Q18685734": "The child sits with angels around the throne. The panel is the whole scene.",
        "Q18685804": "Anne Willing Bingham was a Philadelphia sitter. Stuart paints her in a white dress.",
        "Q18686471": "A hare, fruit, and a copper pot share one table. Nothing in the picture is a portrait.",
        "Q18686934": "Thomas Mifflin and Sarah Morris sit at a work table. Copley keeps both of them in the same quiet pose.",
        "Q18687773": "A table of objects sits in front of an open window on Place Ravignan.",
        "Q18688169": "Two figures ride in an open carriage. The horse and the reins stay in the same plane as the sitters.",
        "Q18688230": "Venus arrives over the water with the figures who attend her.",
        "Q18688391": "Figures rest in an open field. The picture is the calm after a conflict, hung as a pair with War.",
        "Q18689388": "A son is about to leave a farm kitchen. The family stays seated around him.",
        "Q18689378": "Eakins shows the sculptor William Rush at work on a figure of the Schuylkill.",
        "Q18857549": "Two drinkers share a table with a skeleton. The warning is in the room, not in a caption.",
        "Q19660492": "The Bucintoro, the Venetian state barge, is at the Molo on Ascension Day.",
        "Q20180160": "Tanner paints his mother seated in a dark chair, years before The Annunciation.",
    ]

    private static func makeRows() -> [CatalogRow] {
        [
            row(
                "Q773861",
                "Thomas Eakins",
                "The Gross Clinic",
                "1875",
                "Thomas Eakins, American - Portrait of Dr. Samuel D. Gross (The Gross Clinic) - Google Art Project.jpg",
                "Oil on canvas. A surgery at Jefferson Medical College."
            ),
            row(
                "Q698518",
                "Marcel Duchamp",
                "Nude Descending a Staircase No. 2",
                "1912",
                "Duchamp - Nude Descending a Staircase.jpg",
                "Oil on canvas. One figure broken into overlapping steps."
            ),
            row(
                "Q7756187",
                "Edward Hicks",
                "The Peaceable Kingdom",
                "1834",
                "Edward Hicks - Peaceable Kingdom.jpg",
                "Oil on canvas. Animals and children share one ground."
            ),
            row(
                "Q3399414",
                "Peter Paul Rubens",
                "Prometheus Bound",
                "1618",
                "Peter Paul Rubens - Prometheus Bound - Google Art Project.jpg",
                "Oil on canvas. An eagle returns to the chained figure."
            ),
            row(
                "Q18749255",
                "Henry Ossawa Tanner",
                "The Annunciation",
                "1898",
                "Henry Ossawa Tanner - The Annunciation - 1898.jpg",
                "Oil on canvas. A column of light in a plain room."
            ),
            row(
                "Q20487081",
                "Mary Cassatt",
                "Woman with a Pearl Necklace in a Loge",
                "1879",
                "Mary Cassatt - Woman with a Pearl Necklace in a Loge - Google Art Project.jpg",
                "Oil on canvas. A sitter in a theater box."
            ),
            row(
                "Q7720394",
                "Joseph Mallord William Turner",
                "The Burning of the Houses of Lords and Commons",
                "1835",
                "Joseph Mallord William Turner - The Burning of the Houses of Lords and Commons, October 16, 1834 - Google Art Project.jpg",
                "Oil on canvas. The fire of 16 October 1834, seen across the Thames."
            ),
            row(
                "Q7714255",
                "Charles Willson Peale",
                "The Artist in His Museum",
                "1822",
                "Charles Willson Peale - The Artist in His Museum - Google Art Project.jpg",
                "Oil on canvas. The painter lifts a curtain on his collection."
            ),
            row(
                "Q18683906",
                "Claude Monet",
                "Poplars",
                "1891",
                "Claude Monet, French - Poplars - Google Art Project.jpg",
                "Oil on canvas. Trees along the River Epte."
            ),
            row(
                "Q18683915",
                "Claude Monet",
                "Port of Le Havre",
                "1874",
                "Claude Monet, French - Port of Le Havre - Google Art Project.jpg",
                "Oil on canvas. Shipping in the harbor."
            ),
            row(
                "Q18683923",
                "Claude Monet",
                "The Japanese Footbridge and the Water Lily Pool, Giverny",
                "1899",
                "Claude Monet, French - The Japanese Footbridge and the Water Lily Pool, Giverny - Google Art Project.jpg",
                "Oil on canvas. The water-lily pool at Giverny."
            ),
            row(
                "Q18685520",
                "Frederic Edwin Church",
                "Pichincha",
                "1867",
                "Frederic Edwin Church, American - Pichincha - Google Art Project.jpg",
                "Oil on canvas. A volcano above a green valley."
            ),
            row(
                "Q18685714",
                "Georges Seurat",
                "Moored Boats and Trees",
                "1890",
                "Georges Seurat, French - Moored Boats and Trees - Google Art Project.jpg",
                "Oil on canvas. Boats and trees built from dotted color."
            ),
            row(
                "Q18685734",
                "Gerard David",
                "Enthroned Virgin and Child, with Angels",
                "1490",
                "Gerard David, Netherlandish (active Bruges), first documented 1484, died 1523 - Enthroned Virgin and Child, with Angels - Google Art Project.jpg",
                "Oil on panel. The child seated among angels."
            ),
            row(
                "Q18685804",
                "Gilbert Stuart",
                "Portrait of Anne Willing Bingham",
                "1797",
                "Gilbert Charles Stuart, American - Portrait of Anne Willing Bingham - Google Art Project.jpg",
                "Oil on canvas. A Philadelphia sitter dressed in white."
            ),
            row(
                "Q18686471",
                "Jean-Baptiste-Siméon Chardin",
                "Still Life with a Hare",
                "1730",
                "Jean-Baptiste-Siméon Chardin, French - Still Life with a Hare - Google Art Project.jpg",
                "Oil on canvas. A hare beside fruit and a copper pot."
            ),
            row(
                "Q18686934",
                "John Singleton Copley",
                "Portrait of Mr. and Mrs. Thomas Mifflin",
                "1773",
                "John Singleton Copley, American - Portrait of Mr. and Mrs. Thomas Mifflin (Sarah Morris) - Google Art Project.jpg",
                "Oil on canvas. A couple seated at a work table."
            ),
            row(
                "Q18687773",
                "Juan Gris",
                "Still Life before an Open Window, Place Ravignan",
                "1915",
                "Juan Gris (José Victoriano González Pérez), Spanish - Still Life before an Open Window, Place Ravignan - Google Art Project.jpg",
                "Oil on canvas. A table set in front of a Paris window."
            ),
            row(
                "Q18688169",
                "Mary Cassatt",
                "A Woman and a Girl Driving",
                "1881",
                "Mary Stevenson Cassatt, American - A Woman and a Girl Driving - Google Art Project.jpg",
                "Oil on canvas. Two figures in an open carriage."
            ),
            row(
                "Q18688230",
                "Nicolas Poussin",
                "The Birth of Venus",
                "1636",
                "Nicolas Poussin, French - The Birth of Venus - Google Art Project.jpg",
                "Oil on canvas. Venus arrives over the water."
            ),
            row(
                "Q18688391",
                "Pierre Puvis de Chavannes",
                "Peace",
                "1867",
                "Pierre Puvis de Chavannes, French - Peace - Google Art Project.jpg",
                "Oil on canvas. Figures at rest in an open field."
            ),
            row(
                "Q18689388",
                "Thomas Hovenden",
                "Breaking Home Ties",
                "1890",
                "Thomas Hovenden, American (born Ireland) - Breaking Home Ties - Google Art Project.jpg",
                "Oil on canvas. A son about to leave a farm kitchen."
            ),
            row(
                "Q18689378",
                "Thomas Eakins",
                "William Rush Carving His Allegorical Figure of the Schuylkill River",
                "1876",
                "Thomas Eakins, American - William Rush Carving His Allegorical Figure of the Schuylkill River - Google Art Project.jpg",
                "Oil on canvas. A sculptor at work on a river figure."
            ),
            row(
                "Q18857549",
                "Judith Leyster",
                "The Last Drop",
                "1639",
                "Judith Leyster, Dutch (active Haarlem and Amsterdam) - The Last Drop (The Gay Cavalier) - Google Art Project.jpg",
                "Oil on canvas. Two drinkers and a skeleton at the table."
            ),
            row(
                "Q19660492",
                "Canaletto",
                "The Bucintoro at the Molo on Ascension Day",
                "1745",
                "Canaletto (Giovanni Antonio Canal), Italian (active Venice, Rome, and England) - The Bucintoro at the Molo on Ascension Day - Google Art Project.jpg",
                "Oil on canvas. The state barge at the Venetian Molo."
            ),
            row(
                "Q20180160",
                "Henry Ossawa Tanner",
                "Portrait of the Artist's Mother",
                "1897",
                "Henry Ossawa Tanner, American (active France) - Portrait of the Artist's Mother - Google Art Project.jpg",
                "Oil on canvas. The sitter seated in a dark chair."
            ),
        ]
    }

    private static func row(
        _ objectID: String,
        _ artist: String,
        _ title: String,
        _ dated: String,
        _ filename: String,
        _ note: String
    ) -> CatalogRow {
        CatalogRow(
            objectID: objectID,
            artist: artist,
            title: title,
            imageURLString: CatalogClient.commonsFilePath(filename),
            dated: dated,
            note: note
        )
    }
}
