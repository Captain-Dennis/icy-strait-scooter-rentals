import XCTest
@testable import IcyStraitScooterRentals

final class BillingCalculatorTests: XCTestCase {
    func testFirstHourIsSeventyFiveFromTheStart() {
        XCTAssertEqual(BillingCalculator.charge(elapsed: 0), Decimal(75))
        XCTAssertEqual(BillingCalculator.charge(elapsed: 1), Decimal(75))
        XCTAssertEqual(BillingCalculator.charge(elapsed: 3600), Decimal(75))
    }

    func testEachStartedHalfHourAfterTheFirst() {
        XCTAssertEqual(BillingCalculator.charge(elapsed: 3601), Decimal(string: "112.50")!)
        XCTAssertEqual(BillingCalculator.charge(elapsed: 5400), Decimal(string: "112.50")!)
        XCTAssertEqual(BillingCalculator.charge(elapsed: 5401), Decimal(150))
        XCTAssertEqual(BillingCalculator.charge(elapsed: 7200), Decimal(150))
        XCTAssertEqual(BillingCalculator.charge(elapsed: 7201), Decimal(string: "187.50")!)
    }

    func testBreakdownCountsExtraHalfHours() {
        let breakdown = BillingCalculator.breakdown(elapsed: 5401)
        XCTAssertEqual(breakdown.extraHalfHours, 2)
        XCTAssertEqual(breakdown.extraAmount, Decimal(75))
        XCTAssertEqual(breakdown.total, Decimal(150))
    }
}
