import SwiftData
import SwiftUI

struct CalendarTabView: View {
    @Query private var rentals: [Rental]
    @State private var month: Date = Season.date(year: 2027, month: 7, day: 1)
    @State private var selectedDay: Date = Season.date(year: 2027, month: 7, day: 4)

    private var snapshots: [RentalSnapshot] {
        RentalOperations.snapshots(from: rentals)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("May 1–September 30, 2027 · 8am–7pm · 6 units/hour")
                        .font(.subheadline)
                        .foregroundStyle(Brand.silver)
                    monthHeader
                    weekdayHeader
                    monthGrid
                    daySlots
                }
                .padding(20)
            }
            .icyScreenBackground()
            .navigationTitle("Calendar")
            .toolbarBackground(Brand.ink, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!canShift(-1))
            Spacer()
            Text(month, format: Date.FormatStyle().month(.wide).year().locale(Locale(identifier: "en_US")))
                .font(BrandFont.title(22))
                .foregroundStyle(.white)
            Spacer()
            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!canShift(1))
        }
        .foregroundStyle(Brand.orange)
    }

    private var weekdayHeader: some View {
        let symbols = AppTimeZone.calendar.shortWeekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.silver)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    let tightness = dayTightness(day)
                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(AppTimeZone.calendar.component(.day, from: day))")
                                .font(.subheadline.weight(.semibold))
                            Circle()
                                .fill(tightness.color)
                                .frame(width: 6, height: 6)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(.white)
                        .background(
                            AppTimeZone.calendar.isDate(day, inSameDayAs: selectedDay) ? Brand.orange.opacity(0.28) : Brand.card,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(minHeight: 44)
                }
            }
        }
    }

    private var daySlots: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDay, format: Date.FormatStyle().weekday(.wide).month(.wide).day().year())
                .font(BrandFont.headline(18))
                .foregroundStyle(.white)
            ForEach(Season.slotHours, id: \.self) { hour in
                let start = Season.slotStart(on: selectedDay, hour: hour)
                let end = Season.slotEnd(on: selectedDay, hour: hour)
                let remaining = CapacityCalculator.remaining(
                    rentals: snapshots,
                    slotStart: start,
                    slotEnd: end,
                    now: end
                )
                HStack {
                    Text(Season.label(forHour: hour))
                        .font(BrandFont.headline(15))
                        .foregroundStyle(.white)
                        .frame(width: 88, alignment: .leading)
                    CapacityMeter(remaining: remaining)
                }
                .padding(12)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func daysInMonth() -> [Date?] {
        let calendar = AppTimeZone.calendar
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let pad = firstWeekday - 1
        var days: [Date?] = Array(repeating: nil, count: pad)
        var cursor = interval.start
        while cursor < interval.end {
            if Season.isInSeason(cursor) {
                days.append(cursor)
            } else {
                days.append(nil)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? interval.end
        }
        return days
    }

    private func dayTightness(_ day: Date) -> (minRemaining: Int, color: Color) {
        var lowest = Season.capacityPerHour
        for hour in Season.slotHours {
            let remaining = CapacityCalculator.remaining(
                rentals: snapshots,
                slotStart: Season.slotStart(on: day, hour: hour),
                slotEnd: Season.slotEnd(on: day, hour: hour),
                now: Season.slotEnd(on: day, hour: hour)
            )
            lowest = min(lowest, remaining)
        }
        let color: Color
        if lowest == 0 {
            color = Brand.danger
        } else if lowest <= 2 {
            color = Brand.orange
        } else {
            color = Brand.ok
        }
        return (lowest, color)
    }

    private func canShift(_ delta: Int) -> Bool {
        guard let next = AppTimeZone.calendar.date(byAdding: .month, value: delta, to: month) else { return false }
        let monthNumber = AppTimeZone.calendar.component(.month, from: next)
        return (5...9).contains(monthNumber) && AppTimeZone.calendar.component(.year, from: next) == 2027
    }

    private func shiftMonth(_ delta: Int) {
        guard let next = AppTimeZone.calendar.date(byAdding: .month, value: delta, to: month) else { return }
        month = next
        if !AppTimeZone.calendar.isDate(selectedDay, equalTo: next, toGranularity: .month) {
            selectedDay = next
        }
    }
}
