import XCTest
@testable import Rampin

final class RailFoldTests: XCTestCase {
    func test_waitingOnlySampling_skipsHookedAndSettled() throws {
        var rail = makeCrate(waiting: 2)
        rail.works[0].seat = .settled
        rail.works[1].seat = .hooked
        let extra = try file(on: &rail, "Q-extra", "A", "Alpha")
        let extra2 = try file(on: &rail, "Q-extra2", "B", "Beta")
        let extra3 = try file(on: &rail, "Q-extra3", "C", "Gamma")
        try rail.spreadRail(preferring: .title)
        let planted = Set(rail.planted.map(\.workID))
        XCTAssertFalse(planted.contains(rail.works[0].id))
        XCTAssertFalse(planted.contains(rail.works[1].id))
        XCTAssertEqual(planted, [extra, extra2, extra3])
    }

    func test_sharedArtistXORTitleCartel() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        let fields = Set(rail.planted.map(\.cartel.field))
        XCTAssertEqual(fields, [.title])
        XCTAssertEqual(rail.cartelField, .title)
        let texts = rail.planted.map(\.cartel.text)
        XCTAssertEqual(Set(texts).count, 3)
    }

    func test_hookWithoutLift_isRefused() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        let peg = rail.planted[0]
        XCTAssertThrowsError(try rail.hookRampin(peg.id)) { error in
            XCTAssertEqual(error as? RailFault, .hookWithoutLift)
        }
        XCTAssertTrue(rail.hookMarks.isEmpty)
        XCTAssertEqual(rail.works.filter(\.seat.isWaiting).count, 3)
    }

    func test_matchSeatsHooked() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        let peg = rail.planted[0]
        try rail.liftWork(peg.workID)
        XCTAssertEqual(rail.caption(for: peg.workID), .lifted)
        XCTAssertEqual(rail.works.first { $0.id == peg.workID }?.seat, .waiting)
        let kind = try rail.hookRampin(peg.id)
        XCTAssertEqual(kind, .hook)
        XCTAssertEqual(rail.works.first { $0.id == peg.workID }?.seat, .hooked)
        XCTAssertEqual(rail.caption(for: peg.workID), .hooked)
        XCTAssertEqual(rail.hookMarks.count, 1)
        XCTAssertNil(rail.liftedWorkID)
    }

    func test_missReturnsWaiting_andKeepsDropMark() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        let lifted = rail.planted[0]
        let other = rail.planted[1]
        try rail.liftWork(lifted.workID)
        let kind = try rail.hookRampin(other.id)
        XCTAssertEqual(kind, .drop)
        XCTAssertEqual(rail.works.first { $0.id == lifted.workID }?.seat, .waiting)
        XCTAssertEqual(rail.caption(for: lifted.workID), .waiting)
        XCTAssertEqual(rail.dropMarks.count, 1)
        XCTAssertTrue(rail.planted.first { $0.id == other.id }?.isStruck ?? false)
    }

    func test_thirdHookMarkSettles_andLeavesThePool() throws {
        var rail = makeCrate(waiting: 6)
        try rail.spreadRail(preferring: .title)
        let firstTrio = rail.planted
        for peg in firstTrio {
            try rail.liftWork(peg.workID)
            _ = try rail.hookRampin(peg.id)
        }
        XCTAssertEqual(rail.fold, .settled)
        for peg in firstTrio {
            XCTAssertEqual(rail.works.first { $0.id == peg.workID }?.seat, .settled)
        }
        XCTAssertTrue(rail.hookPool.allSatisfy { work in
            !firstTrio.contains(where: { $0.workID == work.id })
        })
        try rail.spreadRail(preferring: .artist)
        XCTAssertEqual(rail.fold, .spread)
        let second = Set(rail.planted.map(\.workID))
        for peg in firstTrio {
            XCTAssertFalse(second.contains(peg.workID), "Settled leaving the pool")
        }
    }

    func test_retractFoldBack_fromSettledToSpread() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        for peg in rail.planted {
            try rail.liftWork(peg.workID)
            _ = try rail.hookRampin(peg.id)
        }
        XCTAssertEqual(rail.fold, .settled)
        try rail.retractNewestMark()
        XCTAssertEqual(rail.fold, .spread)
        let waiting = rail.works.filter(\.seat.isWaiting)
        let hooked = rail.works.filter(\.seat.isHooked)
        XCTAssertEqual(waiting.count, 1)
        XCTAssertEqual(hooked.count, 2)
    }

    func test_bareUnderThreeWaitingWorks() throws {
        var rail = makeCrate(waiting: 2)
        try rail.spreadRail()
        XCTAssertEqual(rail.fold, .bare)
        XCTAssertTrue(rail.planted.isEmpty)
        XCTAssertFalse(rail.canLift)
        XCTAssertFalse(rail.canHook)
    }

    func test_secondSpreadWhileSpread_isRefused() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        XCTAssertThrowsError(try rail.spreadRail()) { error in
            XCTAssertEqual(error as? RailFault, .alreadySpread)
        }
    }

    func test_duplicateAccessionFocuses_andDoesNotResetFold() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        let fold = rail.fold
        let count = rail.works.count
        let row = CatalogRow(
            objectID: rail.works[0].objectID,
            artist: "Other",
            title: "Other",
            imageURLString: nil,
            dated: nil
        )
        let focus = try rail.fileWork(row)
        XCTAssertEqual(focus, .focused(rail.works[0].id))
        XCTAssertEqual(rail.works.count, count)
        XCTAssertEqual(rail.fold, fold)
        XCTAssertEqual(rail.focusedWorkID, rail.works[0].id)
    }

    func test_dropRampinWithoutLift_isRefused() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        XCTAssertThrowsError(try rail.dropRampin(rail.planted[0].id)) { error in
            XCTAssertEqual(error as? RailFault, .dropWithoutLift)
        }
    }

    func test_emptyObjectID_isRefused() {
        var rail = Rail.empty
        XCTAssertThrowsError(try rail.fileWork(CatalogRow(objectID: "  ", artist: "A", title: "B", imageURLString: nil, dated: nil))) { error in
            XCTAssertEqual(error as? RailFault, .emptyObjectID)
        }
    }

    func test_retractDrop_onlyDropsThatMiss() throws {
        var rail = makeCrate(waiting: 3)
        try rail.spreadRail(preferring: .title)
        let lifted = rail.planted[0]
        let other = rail.planted[1]
        try rail.liftWork(lifted.workID)
        try rail.dropRampin(other.id)
        XCTAssertEqual(rail.dropMarks.count, 1)
        try rail.retractNewestMark()
        XCTAssertTrue(rail.dropMarks.isEmpty)
        XCTAssertEqual(rail.fold, .spread)
        XCTAssertEqual(rail.works.filter(\.seat.isWaiting).count, 3)
        XCTAssertFalse(rail.planted.first { $0.id == other.id }?.isStruck ?? true)
    }

    func test_primaryVerb_emptyPopulatedInvalid() throws {
        var empty = Rail.empty
        XCTAssertEqual(empty.fold, .bare)
        XCTAssertFalse(empty.canLift)
        XCTAssertFalse(empty.canHook)
        XCTAssertTrue(empty.canSpread)

        var populated = makeCrate(waiting: 3)
        try populated.spreadRail(preferring: .title)
        XCTAssertTrue(populated.canLift)
        XCTAssertFalse(populated.canHook)
        try populated.liftWork(populated.planted[0].workID)
        XCTAssertTrue(populated.canHook)

        XCTAssertThrowsError(try empty.liftWork(UUID())) { error in
            XCTAssertEqual(error as? RailFault, .notSpread)
        }
    }

    func test_seedIsSpread_neverBare() {
        let seeded = RailSeed.rail()
        XCTAssertEqual(seeded.fold, .spread)
        XCTAssertTrue(seeded.onboardingComplete)
        XCTAssertGreaterThanOrEqual(seeded.waitingWorks.count, 4)
        XCTAssertEqual(seeded.planted.count, 3)
        XCTAssertTrue(seeded.canLift)
        XCTAssertTrue(seeded.canHook)
        XCTAssertFalse(seeded.hookMarks.isEmpty)
        XCTAssertGreaterThanOrEqual(seeded.dropMarks.count, 3)
        XCTAssertNotEqual(seeded.fold, .bare)
    }

    private func makeCrate(waiting: Int) -> Rail {
        var rail = Rail.empty
        let rows = PmaShelf.bundled.rows
        for index in 0 ..< waiting {
            let row = rows[index]
            let day = Date(timeIntervalSince1970: 1_700_000_000 + Double(index) * 86_400)
            _ = try? rail.fileWork(row, now: day)
        }
        return rail
    }

    @discardableResult
    private func file(on rail: inout Rail, _ objectID: String, _ artist: String, _ title: String) throws -> UUID {
        let focus = try rail.fileWork(
            CatalogRow(objectID: objectID, artist: artist, title: title, imageURLString: nil, dated: nil),
            now: Date(timeIntervalSince1970: 1_800_000_000 + Double(rail.works.count) * 86_400)
        )
        if case .inserted(let id) = focus { return id }
        XCTFail("expected insert")
        return UUID()
    }
}
