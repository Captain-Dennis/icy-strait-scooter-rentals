import Foundation

enum CapacityCalculator {
    static let maxPerHour = Season.capacityPerHour

    static func occupancy(
        rentals: [RentalSnapshot],
        slotStart: Date,
        slotEnd: Date,
        now: Date
    ) -> Int {
        rentals.filter { rental in
            overlaps(rental, slotStart: slotStart, slotEnd: slotEnd, now: now)
        }.count
    }

    static func remaining(
        rentals: [RentalSnapshot],
        slotStart: Date,
        slotEnd: Date,
        now: Date,
        capacity: Int = CapacityCalculator.maxPerHour
    ) -> Int {
        max(0, capacity - occupancy(rentals: rentals, slotStart: slotStart, slotEnd: slotEnd, now: now))
    }

    static func hasCapacity(
        rentals: [RentalSnapshot],
        at date: Date,
        now: Date,
        capacity: Int = CapacityCalculator.maxPerHour
    ) -> Bool {
        let hour = AppTimeZone.calendar.component(.hour, from: date)
        let day = AppTimeZone.calendar.startOfDay(for: date)
        let start = Season.slotStart(on: day, hour: hour)
        let end = Season.slotEnd(on: day, hour: hour)
        return remaining(rentals: rentals, slotStart: start, slotEnd: end, now: now, capacity: capacity) > 0
    }

    static func overlaps(
        _ rental: RentalSnapshot,
        slotStart: Date,
        slotEnd: Date,
        now: Date
    ) -> Bool {
        let start = rental.startedAt
        let end = rental.endedAt ?? now
        return start < slotEnd && end > slotStart
    }
}

struct RentalSnapshot: Equatable {
    var id: UUID
    var scooterID: String
    var startedAt: Date
    var endedAt: Date?

    init(id: UUID = UUID(), scooterID: String, startedAt: Date, endedAt: Date?) {
        self.id = id
        self.scooterID = scooterID
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
