import XCTest
@testable import Rampin

final class RailJobTests: XCTestCase {
    func test_schemeRoutesFourDestinations() {
        XCTAssertEqual(RailJob.parse(URL(string: "rampin://quiz")!), .quiz)
        XCTAssertEqual(RailJob.parse(URL(string: "rampin://explore")!), .explore)
        XCTAssertEqual(RailJob.parse(URL(string: "rampin://saved")!), .saved)
        XCTAssertEqual(RailJob.parse(URL(string: "rampin://settings")!), .settings)
        XCTAssertEqual(RailJob.parse(URL(string: "rampin://spread")!), .spread)
        XCTAssertEqual(RailJob.parse(URL(string: "rampin://lift")!), .lift)
        XCTAssertEqual(RailJob.parse(URL(string: "rampin://hook")!), .hook)
    }

    func test_httpsHostMatchesTheSameJobs() {
        XCTAssertEqual(RailJob.parse(URL(string: "https://rampin-hook.pro/quiz")!), .quiz)
        XCTAssertEqual(RailJob.parse(URL(string: "https://rampin-hook.pro/explore")!), .explore)
        XCTAssertEqual(RailJob.parse(URL(string: "https://rampin-hook.pro/saved")!), .saved)
        XCTAssertEqual(RailJob.parse(URL(string: "https://rampin-hook.pro/settings")!), .settings)
        XCTAssertEqual(RailJob.parse(URL(string: "https://rampin-hook.pro/contact-us")!), .settings)
        XCTAssertEqual(RailJob.parse(URL(string: "https://rampin-hook.pro")!), .quiz)
    }

    func test_jobCoversNeverUseAGameTab() {
        XCTAssertNil(RailJob.quiz.cover)
        XCTAssertEqual(RailJob.explore.cover, .explore)
        XCTAssertEqual(RailJob.saved.cover, .saved)
        XCTAssertEqual(RailJob.settings.cover, .settings)
        XCTAssertFalse(RailCover.allCases.contains(where: { $0.rawValue == "game" }))
    }

    func test_notificationParsesOnce() {
        let notice = Notification(
            name: .railJob,
            userInfo: [RailPost.key: RailJob.saved.rawValue]
        )
        XCTAssertEqual(RailJob.parse(notification: notice), .saved)
        let empty = Notification(name: .railJob)
        XCTAssertNil(RailJob.parse(notification: empty))
    }
}
