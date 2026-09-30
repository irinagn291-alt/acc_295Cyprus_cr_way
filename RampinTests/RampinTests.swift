import XCTest
@testable import Rampin

final class RampinTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: RampinApp.self), "RampinApp")
    }

    func test_daykeyUsesStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var parts = DateComponents()
        parts.year = 2023
        parts.month = 12
        parts.day = 1
        parts.hour = 18
        let date = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        XCTAssertEqual(Daykey.stamp(date, calendar: calendar), 20231201)
        XCTAssertEqual(Daykey.shifting(20231201, by: 1, calendar: calendar), 20231202)
    }

    func test_dayLabelFormatsMonthAndDay() {
        XCTAssertEqual(RailFigures.dayLabel(20260915), "Sep 15")
        XCTAssertEqual(RailFigures.daykey(20260918), "Sep 18")
    }
}
