import SwiftUI

struct AchievementsView: View {
    @ObservedObject var store: DataStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(AchievementDefinition.all) { achievement in
                        AchievementBadgeCard(
                            achievement: achievement,
                            isUnlocked: store.unlockedAchievementIDs.contains(achievement.id)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var summaryCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Progress")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                HStack(spacing: 0) {
                    statItem(value: "\(store.entriesCreated)", label: "Entries")
                    Divider().frame(height: 36).background(Color("AppTextSecondary").opacity(0.3))
                    statItem(value: "\(store.sessionsCompleted)", label: "Sessions")
                    Divider().frame(height: 36).background(Color("AppTextSecondary").opacity(0.3))
                    statItem(value: "\(store.streakDays)", label: "Streak")
                    Divider().frame(height: 36).background(Color("AppTextSecondary").opacity(0.3))
                    statItem(value: "\(store.totalMinutesPracticed)", label: "Minutes")
                }
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("AppAccent"))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AchievementBadgeCard: View {
    let achievement: AchievementDefinition
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if isUnlocked {
                    Image("DecorBadge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                } else {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(Color("AppTextSecondary").opacity(0.5))
                        .frame(width: 52, height: 52)
                }
            }

            Text(achievement.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isUnlocked ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                .multilineTextAlignment(.center)

            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color("AppSurface"))
                .shadow(color: Color.black.opacity(isUnlocked ? 0.2 : 0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isUnlocked ? Color("AppAccent").opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .accessibilityIdentifier("achievement_\(achievement.id)")
    }
}
