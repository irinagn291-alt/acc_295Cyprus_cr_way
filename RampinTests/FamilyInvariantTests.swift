import XCTest
@testable import Rampin

/// Family art_quiz invariant: Quiz draws from saved works. Misses are reviewable. Collecting without a test is the crate clone.
final class FamilyInvariantTests: XCTestCase {
    func test_familyInvariant_quizDrawsFromSavedWorks_missesStayReviewable() throws {
        var rail = Rail.empty
        let clinic = catalog("Q773861", "Thomas Eakins", "The Gross Clinic")
        let nude = catalog("Q698518", "Marcel Duchamp", "Nude Descending a Staircase No. 2")
        let kingdom = catalog("Q7756187", "Edward Hicks", "The Peaceable Kingdom")
        let extra = catalog("Q3399414", "Peter Paul Rubens", "Prometheus Bound")

        _ = try rail.fileWork(clinic, now: Date(timeIntervalSince1970: 1_700_000_000))
        _ = try rail.fileWork(nude, now: Date(timeIntervalSince1970: 1_700_086_400))
        _ = try rail.fileWork(kingdom, now: Date(timeIntervalSince1970: 1_700_172_800))
        _ = try rail.fileWork(extra, now: Date(timeIntervalSince1970: 1_700_259_200))

        XCTAssertEqual(rail.fold, .bare)
        XCTAssertTrue(rail.hookMarks.isEmpty)
        XCTAssertTrue(rail.dropMarks.isEmpty)
        XCTAssertEqual(rail.waitingWorks.count, 4, "Collecting without a test is the crate clone")

        try rail.spreadRail(preferring: .title)
        XCTAssertEqual(rail.fold, .spread)
        let sampledIDs = Set(rail.planted.map(\.workID))
        let savedIDs = Set(rail.works.map(\.id))
        XCTAssertTrue(sampledIDs.isSubset(of: savedIDs), "Quiz draws from saved works")
        XCTAssertEqual(rail.planted.count, 3)

        let lifted = rail.waitingOnRail[0]
        let wrong = rail.planted.first { $0.workID != lifted.id }!
        try rail.liftWork(lifted.id)
        _ = try rail.hookRampin(wrong.id)
        XCTAssertEqual(rail.works.first { $0.id == lifted.id }?.seat, .waiting)
        XCTAssertEqual(rail.reviewableDrops.count, 1, "Misses are reviewable")
        XCTAssertEqual(rail.dropMarks.first?.workID, lifted.id)
    }

    private func catalog(_ objectID: String, _ artist: String, _ title: String) -> CatalogRow {
        CatalogRow(objectID: objectID, artist: artist, title: title, imageURLString: nil, dated: nil)
    }
}
