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
            ZStack {
                Color("AppBackground")
                    .overlay {
                        Image("HeroBackground")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.5)
                    }
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                    CalmCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("This Week")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Which closes stuck, and which moves slipped.")
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }

                    CalmCard {
                        VStack(alignment: .leading, spacing: 12) {
                            row("Days closed", "\(summary.closesCount)")
                            row("Moves done", "\(summary.movesDone)/\(summary.movesDue)")
                            row("Wind-down minutes", "\(summary.breathMinutes)")
                            row("Close streak", "\(summary.streak) days")
                        }
                    }

                    if !summary.topDrains.isEmpty {
                        CalmCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Repeated drains")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                FlowTagRow(tags: summary.topDrains)
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
            .clearScrollBackground()
            }
            .navigationTitle("Weekly Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .background(Color.clear)
        }
        .background(Color.clear)
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
        if summary.closesCount == 0 {
            return "No closes yet this week — one 3-2-1 tonight is enough to start the board."
        }
        if summary.moveRate >= 0.7 {
            return "Most parked moves actually happened. Keep the list to one action."
        }
        if summary.breathMinutes >= 10 {
            return "Wind-down showed up. Keep it after the close, not instead of it."
        }
        return "Notice which drains repeat — that is the window to protect tomorrow."
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
