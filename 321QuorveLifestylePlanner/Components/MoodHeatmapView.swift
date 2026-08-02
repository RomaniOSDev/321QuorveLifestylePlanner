import SwiftUI

struct MoodHeatmapView: View {
    let moods: [Mood]
    let intensityProvider: (Date) -> Double

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let days = DateHelpers.last28Days()

        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days, id: \.self) { day in
                let intensity = intensityProvider(day)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(cellColor(intensity: intensity))
                    .frame(height: 28)
                    .overlay {
                        if let mood = moods.first(where: { DateHelpers.isSameDay($0.date, day) }) {
                            Text(mood.emoji)
                                .font(.system(size: 12))
                        }
                    }
                    .accessibilityLabel(dayLabel(day, intensity: intensity))
            }
        }
    }

    private func cellColor(intensity: Double) -> Color {
        if intensity <= 0 {
            return Color("AppBackground").opacity(0.6)
        }
        return Color("AppAccent").opacity(0.25 + intensity * 0.65)
    }

    private func dayLabel(_ date: Date, intensity: Double) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: date)), intensity \(Int(intensity * 100))%"
    }
}

struct MoodStreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundStyle(Color("AppPrimary"))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) Day Streak")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Keep journaling daily")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Spacer()
        }
    }
}
