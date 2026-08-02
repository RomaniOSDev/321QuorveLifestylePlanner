import Charts
import SwiftUI

struct StatisticsView: View {
    @ObservedObject var store: DataStore
    var embedded: Bool = false
    @State private var showWeeklyReview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !embedded {
                    Text("Statistics")
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }

                overviewCard
                moodChartCard
                habitChartCard
                sessionsChartCard

                Button {
                    FeedbackHelper.tap()
                    showWeeklyReview = true
                } label: {
                    Label("Open Weekly Review", systemImage: "calendar.badge.clock")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color("AppSurface"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color("AppAccent").opacity(0.4), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $showWeeklyReview) {
            WeeklyReviewView(store: store)
        }
    }

    private var overviewCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Overview")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    overviewTile(title: "Entries", value: "\(store.entriesCreated)", icon: "book.fill")
                    overviewTile(title: "Sessions", value: "\(store.sessionsCompleted)", icon: "wind")
                    overviewTile(title: "Streak", value: "\(store.streakDays)d", icon: "flame.fill")
                    overviewTile(title: "Minutes", value: "\(store.totalMinutesPracticed)", icon: "clock.fill")
                }
            }
        }
    }

    private func overviewTile(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color("AppPrimary"))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color("AppBackground").opacity(0.45))
        )
    }

    private var moodChartCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mood Trend (14 days)")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                let points = store.moodTrend(days: 14)
                if points.allSatisfy({ $0.intensity <= 0 }) {
                    emptyChartHint("Log moods to see your emotional trend.")
                } else {
                    Chart(points) { point in
                        AreaMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Mood", point.intensity)
                        )
                        .foregroundStyle(Color("AppAccent").opacity(0.25))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Mood", point.intensity)
                        )
                        .foregroundStyle(Color("AppAccent"))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Mood", point.intensity)
                        )
                        .foregroundStyle(Color("AppPrimary"))
                        .symbolSize(point.intensity > 0 ? 36 : 0)
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis {
                        AxisMarks(values: [0, 0.5, 1]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color("AppTextSecondary").opacity(0.25))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(v == 0 ? "Low" : v == 1 ? "High" : "Mid")
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                    .frame(height: 180)
                    .accessibilityIdentifier("mood_trend_chart")
                }
            }
        }
    }

    private var habitChartCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Habit Completion (7 days)")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                let points = store.habitCompletionTrend(days: 7)
                if points.allSatisfy({ $0.rate <= 0 }) {
                    emptyChartHint("Complete habits to unlock this chart.")
                } else {
                    Chart(points) { point in
                        BarMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Rate", point.rate * 100)
                        )
                        .foregroundStyle(Color("AppPrimary").gradient)
                        .cornerRadius(6)
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 50, 100]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color("AppTextSecondary").opacity(0.25))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))%")
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                    .frame(height: 180)
                    .accessibilityIdentifier("habit_completion_chart")
                }
            }
        }
    }

    private var sessionsChartCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Breathing Minutes (14 days)")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                let points = store.sessionMinutesTrend(days: 14)
                if points.allSatisfy({ $0.minutes <= 0 }) {
                    emptyChartHint("Finish a breathing session to see practice time.")
                } else {
                    Chart(points) { point in
                        BarMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Minutes", point.minutes)
                        )
                        .foregroundStyle(Color("AppAccent").gradient)
                        .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color("AppTextSecondary").opacity(0.25))
                            AxisValueLabel()
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                    .frame(height: 180)
                    .accessibilityIdentifier("sessions_chart")
                }
            }
        }
    }

    private func emptyChartHint(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundStyle(Color("AppAccent"))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20)
    }
}

struct MoodTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let intensity: Double
}

struct HabitTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
}

struct SessionTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}
