import Foundation

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isUnlocked: (AppStats) -> Bool
}

struct AppStats {
    var entriesCreated: Int
    var sessionsCompleted: Int
    var streakDays: Int
    var totalMinutesPracticed: Int
}

extension AchievementDefinition {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_step",
            title: "First Step",
            description: "Created the first journal entry.",
            icon: "leaf.fill",
            isUnlocked: { $0.entriesCreated >= 1 }
        ),
        AchievementDefinition(
            id: "mindful_routine",
            title: "Mindful Routine",
            description: "Completed 5 meditation sessions.",
            icon: "wind",
            isUnlocked: { $0.sessionsCompleted >= 5 }
        ),
        AchievementDefinition(
            id: "consistent_tracker",
            title: "Consistent Tracker",
            description: "Tracked moods for a week straight.",
            icon: "calendar",
            isUnlocked: { $0.streakDays >= 7 }
        ),
        AchievementDefinition(
            id: "dedication",
            title: "Dedication",
            description: "Logged 50 total minutes in meditation.",
            icon: "clock.fill",
            isUnlocked: { $0.totalMinutesPracticed >= 50 }
        ),
        AchievementDefinition(
            id: "getting_going",
            title: "Getting Going",
            description: "Reached 10 items.",
            icon: "star.fill",
            isUnlocked: { $0.entriesCreated >= 10 }
        ),
        AchievementDefinition(
            id: "power_user",
            title: "Power User",
            description: "Reached 50 items.",
            icon: "bolt.fill",
            isUnlocked: { $0.entriesCreated >= 50 }
        ),
        AchievementDefinition(
            id: "active_user",
            title: "Active User",
            description: "Completed 10 sessions.",
            icon: "figure.mind.and.body",
            isUnlocked: { $0.sessionsCompleted >= 10 }
        ),
        AchievementDefinition(
            id: "dedicated_user",
            title: "Dedicated User",
            description: "Completed 50 sessions.",
            icon: "crown.fill",
            isUnlocked: { $0.sessionsCompleted >= 50 }
        )
    ]
}
