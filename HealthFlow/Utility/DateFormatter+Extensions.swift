import Foundation

extension DateFormatter {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

extension Calendar {
    func dayBoundary(daysBack: Int, from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: date)
        guard let start = calendar.date(byAdding: .day, value: -daysBack, to: end) else {
            return (end, end)
        }
        return (start, end)
    }
}