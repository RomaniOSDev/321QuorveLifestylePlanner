import Combine
import Foundation

@MainActor
final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var dayCloses: [DayClose] = []
    @Published var sessionLog: [BreathingSessionRecord] = []
    @Published var breathCycleSettings: [Int] = [4, 7, 8]
    @Published var sessionsCompleted: Int = 0
    @Published var totalMinutesPracticed: Int = 0
    @Published var hasSeenOnboarding: Bool = false
    @Published var weeklyBreathGoalMinutes: Int = 30
    @Published var unlockedAchievementIDs: Set<String> = []

    private let defaults = UserDefaults.standard
    private let closesKey = "quorve_day_closes"
    private let sessionsLogKey = "quorve_session_log"
    private let breathKey = "quorve_breath_cycle"
    private let sessionsKey = "quorve_sessions"
    private let minutesKey = "quorve_minutes"
    private let onboardingKey = "quorve_onboarding"
    private let weeklyGoalKey = "quorve_weekly_breath_goal"

    private init() {
        load()
    }

    var closesCount: Int { dayCloses.count }

    var entriesCreated: Int { closesCount }

    var movesCompleted: Int {
        dayCloses.filter(\.isMoveDone).count
    }

    var streakDays: Int {
        DateHelpers.closeStreak(from: dayCloses)
    }

    var stats: AppStats {
        AppStats(
            entriesCreated: closesCount,
            sessionsCompleted: sessionsCompleted,
            streakDays: streakDays,
            totalMinutesPracticed: totalMinutesPracticed
        )
    }

    var todayClose: DayClose? {
        dayCloses.first { DateHelpers.isSameDay($0.date, Date()) }
    }

    var hasClosedToday: Bool { todayClose != nil }

    /// Yesterday's close carries the move that belongs to today.
    var todaysPlannedMove: DayClose? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            return nil
        }
        return dayCloses.first { DateHelpers.isSameDay($0.date, yesterday) }
    }

    var weeklyBreathMinutes: Int {
        let weekStart = DateHelpers.startOfWeek()
        return sessionLog
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.minutes }
    }

    var weeklyBreathProgress: Double {
        guard weeklyBreathGoalMinutes > 0 else { return 0 }
        return min(Double(weeklyBreathMinutes) / Double(weeklyBreathGoalMinutes), 1)
    }

    var weekCloses: [DayClose] {
        let days = DateHelpers.daysInCurrentWeek()
        return dayCloses.filter { close in
            days.contains { DateHelpers.isSameDay($0, close.date) }
        }
    }

    func close(for date: Date) -> DayClose? {
        dayCloses.first { DateHelpers.isSameDay($0.date, date) }
    }

    func load() {
        if let data = defaults.data(forKey: closesKey),
           let decoded = try? JSONDecoder().decode([DayClose].self, from: data) {
            dayCloses = decoded
        }
        if let data = defaults.data(forKey: sessionsLogKey),
           let decoded = try? JSONDecoder().decode([BreathingSessionRecord].self, from: data) {
            sessionLog = decoded
        }
        if let cycle = defaults.array(forKey: breathKey) as? [Int], cycle.count == 3 {
            breathCycleSettings = cycle
        }
        sessionsCompleted = defaults.integer(forKey: sessionsKey)
        totalMinutesPracticed = defaults.integer(forKey: minutesKey)
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        let goal = defaults.integer(forKey: weeklyGoalKey)
        weeklyBreathGoalMinutes = goal > 0 ? goal : 30
    }

    func save() {
        if let data = try? JSONEncoder().encode(dayCloses) {
            defaults.set(data, forKey: closesKey)
        }
        if let data = try? JSONEncoder().encode(sessionLog) {
            defaults.set(data, forKey: sessionsLogKey)
        }
        defaults.set(breathCycleSettings, forKey: breathKey)
        defaults.set(sessionsCompleted, forKey: sessionsKey)
        defaults.set(totalMinutesPracticed, forKey: minutesKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
        defaults.set(weeklyBreathGoalMinutes, forKey: weeklyGoalKey)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        save()
    }

    @discardableResult
    func saveDayClose(
        wins: [String],
        drains: [String],
        drainTags: [String],
        moveTitle: String,
        moveSlot: MoveSlot,
        moveHour: Int,
        moveMinute: Int
    ) -> Bool {
        let draft = DayClose(
            date: Date(),
            wins: wins,
            drains: drains,
            drainTags: drainTags.sorted(),
            moveTitle: moveTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            moveSlot: moveSlot,
            moveHour: min(max(moveHour, 0), 23),
            moveMinute: min(max(moveMinute, 0), 59),
            isMoveDone: false,
            closedAt: Date()
        )
        guard draft.isComplete else {
            FeedbackHelper.warning()
            return false
        }

        if let index = dayCloses.firstIndex(where: { DateHelpers.isSameDay($0.date, Date()) }) {
            let existing = dayCloses[index]
            dayCloses[index] = DayClose(
                id: existing.id,
                date: Date(),
                wins: draft.wins,
                drains: draft.drains,
                drainTags: draft.drainTags,
                moveTitle: draft.moveTitle,
                moveSlot: draft.moveSlot,
                moveHour: draft.moveHour,
                moveMinute: draft.moveMinute,
                isMoveDone: existing.isMoveDone,
                closedAt: Date()
            )
        } else {
            dayCloses.insert(draft, at: 0)
        }
        save()
        FeedbackHelper.save()
        return true
    }

    func completeTodaysPlannedMove() {
        guard let planned = todaysPlannedMove,
              let index = dayCloses.firstIndex(where: { $0.id == planned.id }) else {
            FeedbackHelper.warning()
            return
        }
        dayCloses[index].isMoveDone = true
        save()
        FeedbackHelper.success()
    }

    func updateBreathSettings(inhale: Int, hold: Int, exhale: Int) {
        breathCycleSettings = [inhale, hold, exhale]
        save()
    }

    func updateWeeklyBreathGoal(_ minutes: Int) {
        weeklyBreathGoalMinutes = min(max(minutes, 5), 300)
        save()
    }

    func completeBreathingSession(minutes: Int, cycles: Int) {
        let loggedMinutes = max(minutes, 1)
        sessionsCompleted += 1
        totalMinutesPracticed += loggedMinutes
        sessionLog.insert(
            BreathingSessionRecord(minutes: loggedMinutes, cycles: max(cycles, 0)),
            at: 0
        )
        save()
        FeedbackHelper.sessionComplete()
    }

    func sessionMinutesTrend(days: Int) -> [SessionTrendPoint] {
        DateHelpers.lastNDays(days).map { day in
            let minutes = sessionLog
                .filter { DateHelpers.isSameDay($0.date, day) }
                .reduce(0) { $0 + $1.minutes }
            return SessionTrendPoint(date: day, minutes: minutes)
        }
    }

    func closeTrend(days: Int) -> [CloseTrendPoint] {
        DateHelpers.lastNDays(days).map { day in
            CloseTrendPoint(date: day, didClose: close(for: day) != nil)
        }
    }

    func moveCompletionTrend(days: Int) -> [HabitTrendPoint] {
        DateHelpers.lastNDays(days).map { day in
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: day) else {
                return HabitTrendPoint(date: day, rate: 0)
            }
            guard let planned = close(for: yesterday) else {
                return HabitTrendPoint(date: day, rate: 0)
            }
            return HabitTrendPoint(date: day, rate: planned.isMoveDone ? 1 : 0)
        }
    }

    func weeklyReviewSummary() -> WeeklyReviewSummary {
        let days = DateHelpers.lastNDays(7)
        let weekCloses = dayCloses.filter { close in
            days.contains { DateHelpers.isSameDay($0, close.date) }
        }
        let movesDue = weekCloses.count
        let movesDone = weekCloses.filter(\.isMoveDone).count
        let tagged = Dictionary(grouping: weekCloses.flatMap(\.drainTags), by: { $0 })
            .map { (tag: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
        let breathMinutes = sessionLog
            .filter { session in days.contains { DateHelpers.isSameDay($0, session.date) } }
            .reduce(0) { $0 + $1.minutes }

        return WeeklyReviewSummary(
            closesCount: weekCloses.count,
            movesDone: movesDone,
            movesDue: movesDue,
            topDrains: Array(tagged.prefix(3).map(\.tag)),
            breathMinutes: breathMinutes,
            streak: streakDays
        )
    }

    func resetAll() {
        dayCloses = []
        sessionLog = []
        breathCycleSettings = [4, 7, 8]
        sessionsCompleted = 0
        totalMinutesPracticed = 0
        weeklyBreathGoalMinutes = 30
        save()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }
}

struct WeeklyReviewSummary {
    let closesCount: Int
    let movesDone: Int
    let movesDue: Int
    let topDrains: [String]
    let breathMinutes: Int
    let streak: Int

    var moveRate: Double {
        guard movesDue > 0 else { return 0 }
        return Double(movesDone) / Double(movesDue)
    }
}

struct CloseTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let didClose: Bool
}
