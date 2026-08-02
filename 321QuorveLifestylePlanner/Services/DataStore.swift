import Combine
import Foundation

@MainActor
final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var moods: [Mood] = []
    @Published var habits: [Habit] = []
    @Published var sessionLog: [BreathingSessionRecord] = []
    @Published var breathCycleSettings: [Int] = [4, 7, 8]
    @Published var sessionsCompleted: Int = 0
    @Published var totalMinutesPracticed: Int = 0
    @Published var hasSeenOnboarding: Bool = false
    @Published var unlockedAchievementIDs: Set<String> = []
    @Published var pendingAchievementBanner: AchievementDefinition?
    @Published var weeklyBreathGoalMinutes: Int = 30
    @Published var streakFreezeDates: [Date] = []
    @Published var streakFreezesUsedThisMonth: Int = 0
    @Published var streakFreezeMonthKey: String = ""

    private var achievementQueue: [AchievementDefinition] = []

    private let defaults = UserDefaults.standard
    private let moodsKey = "quorve_moods"
    private let habitsKey = "quorve_habits"
    private let sessionsLogKey = "quorve_session_log"
    private let breathKey = "quorve_breath_cycle"
    private let sessionsKey = "quorve_sessions"
    private let minutesKey = "quorve_minutes"
    private let onboardingKey = "quorve_onboarding"
    private let achievementsKey = "quorve_achievements"
    private let weeklyGoalKey = "quorve_weekly_breath_goal"
    private let freezeDatesKey = "quorve_streak_freezes"
    private let freezesUsedKey = "quorve_freezes_used"
    private let freezeMonthKey = "quorve_freeze_month"

    private let defaultHabitNames = ["Meditation", "Exercise", "Gratitude"]
    private let maxFreezesPerMonth = 2

    private init() {
        load()
        ensureDefaultHabits()
        refreshFreezeMonthIfNeeded()
    }

    var entriesCreated: Int { moods.count }

    var streakDays: Int {
        DateHelpers.moodStreak(from: moods, freezeDays: streakFreezeDates)
    }

    var streakFreezesRemaining: Int {
        max(0, maxFreezesPerMonth - streakFreezesUsedThisMonth)
    }

    var canUseStreakFreeze: Bool {
        guard streakFreezesRemaining > 0 else { return false }
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: DateHelpers.startOfDay(Date())) else {
            return false
        }
        let yesterdayStart = DateHelpers.startOfDay(yesterday)
        let hasMoodYesterday = moods.contains { DateHelpers.isSameDay($0.date, yesterdayStart) }
        let alreadyFrozen = streakFreezeDates.contains { DateHelpers.isSameDay($0, yesterdayStart) }
        return !hasMoodYesterday && !alreadyFrozen
    }

    var stats: AppStats {
        AppStats(
            entriesCreated: entriesCreated,
            sessionsCompleted: sessionsCompleted,
            streakDays: streakDays,
            totalMinutesPracticed: totalMinutesPracticed
        )
    }

    var todayMood: Mood? {
        moods.first { DateHelpers.isSameDay($0.date, Date()) }
    }

    var todayHabits: [Habit] {
        habits.filter { DateHelpers.isSameDay($0.date, Date()) }
    }

    var pastMoods: [Mood] {
        moods
            .filter { !DateHelpers.isSameDay($0.date, Date()) }
            .sorted { $0.date > $1.date }
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

    func load() {
        if let data = defaults.data(forKey: moodsKey),
           let decoded = try? JSONDecoder().decode([Mood].self, from: data) {
            moods = decoded
        }
        if let data = defaults.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
        if let data = defaults.data(forKey: sessionsLogKey),
           let decoded = try? JSONDecoder().decode([BreathingSessionRecord].self, from: data) {
            sessionLog = decoded
        }
        if let data = defaults.data(forKey: freezeDatesKey),
           let decoded = try? JSONDecoder().decode([Date].self, from: data) {
            streakFreezeDates = decoded
        }
        if let cycle = defaults.array(forKey: breathKey) as? [Int], cycle.count == 3 {
            breathCycleSettings = cycle
        }
        sessionsCompleted = defaults.integer(forKey: sessionsKey)
        totalMinutesPracticed = defaults.integer(forKey: minutesKey)
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        let goal = defaults.integer(forKey: weeklyGoalKey)
        weeklyBreathGoalMinutes = goal > 0 ? goal : 30
        streakFreezesUsedThisMonth = defaults.integer(forKey: freezesUsedKey)
        streakFreezeMonthKey = defaults.string(forKey: freezeMonthKey) ?? ""
        if let ids = defaults.array(forKey: achievementsKey) as? [String] {
            unlockedAchievementIDs = Set(ids)
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(moods) {
            defaults.set(data, forKey: moodsKey)
        }
        if let data = try? JSONEncoder().encode(habits) {
            defaults.set(data, forKey: habitsKey)
        }
        if let data = try? JSONEncoder().encode(sessionLog) {
            defaults.set(data, forKey: sessionsLogKey)
        }
        if let data = try? JSONEncoder().encode(streakFreezeDates) {
            defaults.set(data, forKey: freezeDatesKey)
        }
        defaults.set(breathCycleSettings, forKey: breathKey)
        defaults.set(sessionsCompleted, forKey: sessionsKey)
        defaults.set(totalMinutesPracticed, forKey: minutesKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
        defaults.set(Array(unlockedAchievementIDs), forKey: achievementsKey)
        defaults.set(weeklyBreathGoalMinutes, forKey: weeklyGoalKey)
        defaults.set(streakFreezesUsedThisMonth, forKey: freezesUsedKey)
        defaults.set(streakFreezeMonthKey, forKey: freezeMonthKey)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        save()
    }

    func addMood(emoji: String, note: String, tags: [String] = []) {
        if let index = moods.firstIndex(where: { DateHelpers.isSameDay($0.date, Date()) }) {
            moods[index].emoji = emoji
            moods[index].note = note
            moods[index].tags = tags
            moods[index].date = Date()
        } else {
            moods.insert(Mood(emoji: emoji, note: note, tags: tags), at: 0)
        }
        save()
        checkAchievements()
        FeedbackHelper.save()
    }

    func deleteMood(_ mood: Mood) {
        moods.removeAll { $0.id == mood.id }
        save()
        FeedbackHelper.tap()
    }

    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isCompleted.toggle()
        save()
        FeedbackHelper.tap()
    }

    func updateHabitNote(_ habit: Habit, note: String) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].note = note
        save()
    }

    func completeHabit(_ habit: Habit, note: String) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].isCompleted = true
        habits[index].note = note
        save()
        FeedbackHelper.save()
    }

    func addHabit(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackHelper.warning()
            return
        }
        habits.append(Habit(name: trimmed))
        save()
        FeedbackHelper.save()
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        save()
        FeedbackHelper.tap()
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
        checkAchievements()
        FeedbackHelper.sessionComplete()
    }

    @discardableResult
    func useStreakFreeze() -> Bool {
        refreshFreezeMonthIfNeeded()
        guard canUseStreakFreeze else {
            FeedbackHelper.warning()
            return false
        }
        guard let yesterday = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: DateHelpers.startOfDay(Date())
        ) else { return false }

        streakFreezeDates.append(DateHelpers.startOfDay(yesterday))
        streakFreezesUsedThisMonth += 1
        save()
        FeedbackHelper.success()
        return true
    }

    func moods(for date: Date) -> [Mood] {
        moods.filter { DateHelpers.isSameDay($0.date, date) }
    }

    func moodIntensity(for date: Date) -> Double {
        let dayMoods = moods(for: date)
        guard !dayMoods.isEmpty else { return 0 }
        let positive: Set<String> = ["😊", "😄", "🙂", "😌", "🥰", "😇"]
        let neutral: Set<String> = ["😐", "🤔", "😴"]
        let scores = dayMoods.map { mood -> Double in
            if positive.contains(mood.emoji) { return 1.0 }
            if neutral.contains(mood.emoji) { return 0.5 }
            return 0.25
        }
        return scores.reduce(0, +) / Double(scores.count)
    }

    func moodTrend(days: Int) -> [MoodTrendPoint] {
        DateHelpers.lastNDays(days).map { day in
            MoodTrendPoint(date: day, intensity: moodIntensity(for: day))
        }
    }

    func habitCompletionTrend(days: Int) -> [HabitTrendPoint] {
        DateHelpers.lastNDays(days).map { day in
            let dayHabits = habits.filter { DateHelpers.isSameDay($0.date, day) }
            let rate: Double
            if dayHabits.isEmpty {
                rate = 0
            } else {
                let done = dayHabits.filter(\.isCompleted).count
                rate = Double(done) / Double(dayHabits.count)
            }
            return HabitTrendPoint(date: day, rate: rate)
        }
    }

    func sessionMinutesTrend(days: Int) -> [SessionTrendPoint] {
        DateHelpers.lastNDays(days).map { day in
            let minutes = sessionLog
                .filter { DateHelpers.isSameDay($0.date, day) }
                .reduce(0) { $0 + $1.minutes }
            return SessionTrendPoint(date: day, minutes: minutes)
        }
    }

    func weeklyReviewSummary() -> WeeklyReviewSummary {
        let days = DateHelpers.lastNDays(7)
        let weekMoods = moods.filter { mood in
            days.contains { DateHelpers.isSameDay($0, mood.date) }
        }
        let avgIntensity: Double
        if weekMoods.isEmpty {
            avgIntensity = 0
        } else {
            avgIntensity = weekMoods.map { moodIntensity(for: $0.date) }.reduce(0, +) / Double(weekMoods.count)
        }

        let tagged = Dictionary(grouping: weekMoods.flatMap(\.tags), by: { $0 })
            .map { (tag: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        let habitDays = days.map { day -> Double in
            let dayHabits = habits.filter { DateHelpers.isSameDay($0.date, day) }
            guard !dayHabits.isEmpty else { return 0 }
            return Double(dayHabits.filter(\.isCompleted).count) / Double(dayHabits.count)
        }
        let habitAverage = habitDays.isEmpty ? 0 : habitDays.reduce(0, +) / Double(habitDays.count)

        let breathMinutes = sessionLog
            .filter { session in days.contains { DateHelpers.isSameDay($0, session.date) } }
            .reduce(0) { $0 + $1.minutes }

        return WeeklyReviewSummary(
            entriesCount: weekMoods.count,
            averageMoodIntensity: avgIntensity,
            topTags: Array(tagged.prefix(3).map(\.tag)),
            habitCompletion: habitAverage,
            breathMinutes: breathMinutes,
            streak: streakDays
        )
    }

    func resetAll() {
        moods = []
        habits = []
        sessionLog = []
        breathCycleSettings = [4, 7, 8]
        sessionsCompleted = 0
        totalMinutesPracticed = 0
        unlockedAchievementIDs = []
        pendingAchievementBanner = nil
        achievementQueue = []
        weeklyBreathGoalMinutes = 30
        streakFreezeDates = []
        streakFreezesUsedThisMonth = 0
        streakFreezeMonthKey = currentMonthKey()
        ensureDefaultHabits()
        save()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func ensureTodayHabits() {
        let existingToday = habits.filter { DateHelpers.isSameDay($0.date, Date()) }
        guard existingToday.isEmpty else { return }

        let names: [String]
        if let latestDate = habits.map(\.date).max() {
            let previousNames = habits
                .filter { DateHelpers.isSameDay($0.date, latestDate) }
                .map(\.name)
            names = previousNames.isEmpty ? defaultHabitNames : previousNames
        } else {
            names = defaultHabitNames
        }

        for name in names {
            habits.append(Habit(name: name, date: Date()))
        }
        save()
    }

    private func ensureDefaultHabits() {
        ensureTodayHabits()
    }

    private func checkAchievements() {
        for achievement in AchievementDefinition.all {
            guard !unlockedAchievementIDs.contains(achievement.id),
                  achievement.isUnlocked(stats) else { continue }
            unlockedAchievementIDs.insert(achievement.id)
            if pendingAchievementBanner == nil {
                pendingAchievementBanner = achievement
            } else {
                achievementQueue.append(achievement)
            }
            FeedbackHelper.achievementUnlocked()
        }
        save()
    }

    func dismissAchievementBanner() {
        if !achievementQueue.isEmpty {
            pendingAchievementBanner = achievementQueue.removeFirst()
        } else {
            pendingAchievementBanner = nil
        }
    }

    private func refreshFreezeMonthIfNeeded() {
        let key = currentMonthKey()
        if streakFreezeMonthKey != key {
            streakFreezeMonthKey = key
            streakFreezesUsedThisMonth = 0
            save()
        }
    }

    private func currentMonthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}

struct WeeklyReviewSummary {
    let entriesCount: Int
    let averageMoodIntensity: Double
    let topTags: [String]
    let habitCompletion: Double
    let breathMinutes: Int
    let streak: Int

    var moodLabel: String {
        if averageMoodIntensity >= 0.75 { return "Uplifted" }
        if averageMoodIntensity >= 0.45 { return "Balanced" }
        if averageMoodIntensity > 0 { return "Heavy" }
        return "Quiet"
    }
}
