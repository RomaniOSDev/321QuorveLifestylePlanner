import Charts
import SwiftUI

struct StatisticsView: View {
    @ObservedObject var store: DataStore
    @State private var showWeeklyReview = false

    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Week board")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Which evenings closed, and which moves actually happened.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                overviewCard
                weekStrip
                moveChartCard
                drainCard
                weekMovesList

                Button {
                    FeedbackHelper.tap()
                    showWeeklyReview = true
                } label: {
                    Label("Open weekly recap", systemImage: "calendar.badge.clock")
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
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .clearScrollBackground()
        .sheet(isPresented: $showWeeklyReview) {
            WeeklyReviewView(store: store)
        }
    }

    private var overviewCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("This week")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    overviewTile(title: "Days closed", value: "\(store.weekCloses.count)", icon: "checkmark.rectangle.fill")
                    overviewTile(title: "Moves done", value: "\(store.weekCloses.filter(\.isMoveDone).count)", icon: "flag.checkered")
                    overviewTile(title: "Close streak", value: "\(store.streakDays)d", icon: "flame.fill")
                    overviewTile(title: "Wind-down min", value: "\(store.weeklyBreathMinutes)", icon: "moon.haze.fill")
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

    private var weekStrip: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Close map")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                HStack(spacing: 8) {
                    ForEach(DateHelpers.daysInCurrentWeek(), id: \.self) { day in
                        let closed = store.close(for: day)
                        VStack(spacing: 8) {
                            Text(weekdayFormatter.string(from: day))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(closed == nil ? Color("AppBackground").opacity(0.6) : Color("AppPrimary"))
                                .frame(height: 44)
                                .overlay {
                                    if let closed {
                                        Image(systemName: closed.isMoveDone ? "checkmark" : "circle")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color.white)
                                    }
                                }
                            Text(closed == nil ? "—" : (closed?.isMoveDone == true ? "move" : "open"))
                                .font(.caption2)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var moveChartCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Moves that stuck (7 days)")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                let points = store.moveCompletionTrend(days: 7)
                if points.allSatisfy({ $0.rate <= 0 }) && store.weekCloses.isEmpty {
                    emptyChartHint("Close a day to park a move, then mark it done the next morning.")
                } else {
                    Chart(points) { point in
                        BarMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Done", point.rate * 100)
                        )
                        .foregroundStyle(Color("AppPrimary").gradient)
                        .cornerRadius(6)
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 100]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color("AppTextSecondary").opacity(0.25))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(v == 0 ? "Missed" : "Done")
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
                    .accessibilityIdentifier("move_completion_chart")
                }
            }
        }
    }

    private var drainCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Drains that repeated")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                let tags = store.weeklyReviewSummary().topDrains
                if tags.isEmpty {
                    Text("No drain tags yet. They show which windows keep slipping.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    FlowTagRow(tags: tags)
                }
            }
        }
    }

    private var weekMovesList: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parked moves")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                let closes = store.weekCloses.sorted { $0.date > $1.date }
                if closes.isEmpty {
                    Text("Moves appear here after you close a day.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(closes) { close in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: close.isMoveDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(close.isMoveDone ? Color("AppAccent") : Color("AppTextSecondary"))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(close.moveTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("\(shortDate(close.date)) · \(close.moveSlot.title) \(close.moveTimeLabel)")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private func emptyChartHint(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "flag.checkered")
                .foregroundStyle(Color("AppAccent"))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }
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
