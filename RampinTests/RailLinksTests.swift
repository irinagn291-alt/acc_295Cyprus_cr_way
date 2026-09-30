import XCTest
@testable import Rampin

final class RailLinksTests: XCTestCase {
    func test_reviewScreenKeysOpenThreeDifferentScreens() {
        XCTAssertEqual(ReviewHook.today.sheet, .quiz)
        XCTAssertEqual(ReviewHook.log.sheet, .saved)
        XCTAssertEqual(ReviewHook.goals.sheet, .settings)
        XCTAssertEqual(ReviewHook.explore.sheet, .explore)
        let screens = Set([
            ReviewHook.today.sheet,
            ReviewHook.log.sheet,
            ReviewHook.goals.sheet,
        ])
        XCTAssertEqual(screens.count, 3)
        XCTAssertFalse(RailSheet.allCases.contains(where: { $0.rawValue == "game" }))
    }

    func test_consumeReadsProcessInfoOnceAfterOnboarding() {
        var consumed = false
        let first = RailLinks.consume(
            arguments: ["Rampin", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)
        let second = RailLinks.consume(
            arguments: ["Rampin", "-ReviewScreen", "goals"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertNil(second)
    }

    func test_consumeSkipsWhileOnboarding() {
        var consumed = false
        let hook = RailLinks.consume(
            arguments: ["Rampin", "-ReviewScreen", "today"],
            onboardingComplete: false,
            consumed: &consumed
        )
        XCTAssertNil(hook)
        XCTAssertFalse(consumed)
    }

    func test_unknownSlugIsDropped() {
        var consumed = false
        let hook = RailLinks.consume(
            arguments: ["Rampin", "-ReviewScreen", "kiln"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertNil(hook)
        XCTAssertTrue(consumed)
    }
}
