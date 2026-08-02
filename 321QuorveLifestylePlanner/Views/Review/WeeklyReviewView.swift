import SwiftUI

struct GoalProgressRing: View {
    let progress: Double
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color("AppTextSecondary").opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        Color("AppAccent"),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: progress)

                Text("\(Int((min(max(progress, 0), 1)) * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Spacer(minLength: 0)
        }
    }
}

struct WeeklyReviewView: View {
    @ObservedObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    private var summary: WeeklyReviewSummary {
        store.weeklyReviewSummary()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CalmCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("This Week")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("A gentle look at your last 7 days.")
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }

                    CalmCard {
                        VStack(alignment: .leading, spacing: 12) {
                            row("Mood tone", summary.moodLabel)
                            row("Journal entries", "\(summary.entriesCount)")
                            row("Habit completion", "\(Int(summary.habitCompletion * 100))%")
                            row("Breathing minutes", "\(summary.breathMinutes)")
                            row("Current streak", "\(summary.streak) days")
                        }
                    }

                    if !summary.topTags.isEmpty {
                        CalmCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Top mood tags")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                FlowTagRow(tags: summary.topTags)
                            }
                        }
                    }

                    Text(reflectionLine)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Weekly Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
            Text(value)
                .foregroundStyle(Color("AppAccent"))
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private var reflectionLine: String {
        if summary.entriesCount == 0 {
            return "No entries yet this week — a single check-in tomorrow is a beautiful start."
        }
        if summary.habitCompletion >= 0.7 {
            return "Your habits held steady. Protect that rhythm."
        }
        if summary.breathMinutes >= 10 {
            return "Breath practice showed up for you. Keep the minutes gentle and regular."
        }
        return "Notice what felt heavy and what felt light — both belong in your story."
    }
}

struct FlowTagRow: View {
    let tags: [String]

    var body: some View {
        FlexibleTagWrap(tags: tags)
    }
}

private struct FlexibleTagWrap: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunked, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color("AppPrimary").opacity(0.25)))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunked: [[String]] {
        stride(from: 0, to: tags.count, by: 3).map {
            Array(tags[$0..<min($0 + 3, tags.count)])
        }
    }
}
