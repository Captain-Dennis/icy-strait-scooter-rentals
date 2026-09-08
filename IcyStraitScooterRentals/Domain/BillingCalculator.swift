import Foundation

enum BillingCalculator {
    static let firstHour: Decimal = Decimal(string: "75.00")!
    static let additionalHalfHour: Decimal = Decimal(string: "37.50")!
    static let firstHourSeconds: TimeInterval = 3600
    static let halfHourSeconds: TimeInterval = 1800

    /// First hour is a $75 block from the moment checkout starts.
    /// After 60:00, each *started* additional 30 minutes is $37.50.
    /// 0...3600s → $75.00; 3601...5400s → $112.50; 5401...7200s → $150.00.
    static func charge(elapsed seconds: TimeInterval) -> Decimal {
        guard seconds >= 0 else { return 0 }
        if seconds <= firstHourSeconds {
            return firstHour
        }
        let extra = seconds - firstHourSeconds
        let startedHalfHours = Int(ceil(extra / halfHourSeconds))
        return firstHour + Decimal(startedHalfHours) * additionalHalfHour
    }

    static func breakdown(elapsed seconds: TimeInterval) -> BillingBreakdown {
        let total = charge(elapsed: seconds)
        if seconds <= firstHourSeconds {
            return BillingBreakdown(
                elapsed: seconds,
                firstHour: firstHour,
                extraHalfHours: 0,
                extraAmount: 0,
                total: total
            )
        }
        let extra = seconds - firstHourSeconds
        let startedHalfHours = Int(ceil(extra / halfHourSeconds))
        return BillingBreakdown(
            elapsed: seconds,
            firstHour: firstHour,
            extraHalfHours: startedHalfHours,
            extraAmount: Decimal(startedHalfHours) * additionalHalfHour,
            total: total
        )
    }
}

struct BillingBreakdown: Equatable {
    var elapsed: TimeInterval
    var firstHour: Decimal
    var extraHalfHours: Int
    var extraAmount: Decimal
    var total: Decimal
}

enum MoneyFormat {
    static let usd: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static func string(_ value: Decimal) -> String {
        usd.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}
