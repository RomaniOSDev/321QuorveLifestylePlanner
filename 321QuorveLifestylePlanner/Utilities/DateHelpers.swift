import Foundation

enum DateHelpers {
    static let calendar = Calendar.current

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func daysBetween(start: Date, end: Date) -> Int {
        let startDay = startOfDay(start)
        let endDay = startOfDay(end)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    static func moodStreak(from moods: [Mood], freezeDays: [Date] = []) -> Int {
        let uniqueDays = Set(moods.map { startOfDay($0.date) })
        let freezes = Set(freezeDays.map(startOfDay))
        guard !uniqueDays.isEmpty || !freezes.isEmpty else { return 0 }

        var streak = 0
        var cursor = startOfDay(Date())

        // If today isn't logged yet, start from yesterday so streak stays visible.
        if !uniqueDays.contains(cursor) && !freezes.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }

        while uniqueDays.contains(cursor) || freezes.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func last28Days() -> [Date] {
        lastNDays(28)
    }

    static func lastNDays(_ count: Int) -> [Date] {
        (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: startOfDay(Date()))
        }.reversed()
    }

    static func startOfWeek(_ date: Date = Date()) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components).map(startOfDay) ?? startOfDay(date)
    }

    static func daysInCurrentWeek() -> [Date] {
        let start = startOfWeek()
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
