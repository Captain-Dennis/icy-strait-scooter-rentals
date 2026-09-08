import XCTest
@testable import IcyStraitScooterRentals

final class CapacityCalculatorTests: XCTestCase {
    func testHourlyCapIsSix() {
        let day = Season.date(year: 2027, month: 7, day: 4)
        let start = Season.slotStart(on: day, hour: 11)
        let end = Season.slotEnd(on: day, hour: 11)
        let rentals = (0..<6).map { index in
            RentalSnapshot(
                scooterID: "IS-10\(index + 1)",
                startedAt: start.addingTimeInterval(60),
                endedAt: start.addingTimeInterval(40 * 60)
            )
        }
        XCTAssertEqual(CapacityCalculator.occupancy(rentals: rentals, slotStart: start, slotEnd: end, now: end), 6)
        XCTAssertEqual(CapacityCalculator.remaining(rentals: rentals, slotStart: start, slotEnd: end, now: end), 0)
        XCTAssertFalse(CapacityCalculator.hasCapacity(rentals: rentals, at: start.addingTimeInterval(120), now: end))
    }

    func testFourOfSixRemaining() {
        let day = Season.date(year: 2027, month: 7, day: 4)
        let start = Season.slotStart(on: day, hour: 9)
        let end = Season.slotEnd(on: day, hour: 9)
        let rentals = [
            RentalSnapshot(scooterID: "IS-101", startedAt: start, endedAt: end.addingTimeInterval(-60)),
            RentalSnapshot(scooterID: "IS-102", startedAt: start, endedAt: end.addingTimeInterval(-60))
        ]
        XCTAssertEqual(CapacityCalculator.remaining(rentals: rentals, slotStart: start, slotEnd: end, now: end), 4)
    }
}
