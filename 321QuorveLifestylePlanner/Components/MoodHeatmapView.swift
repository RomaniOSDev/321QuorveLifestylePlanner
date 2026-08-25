import SwiftUI

struct MoodHeatmapView: View {
    let closes: [DayClose]
    let didClose: (Date) -> Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let days = DateHelpers.last28Days()

        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days, id: \.self) { day in
                let closed = didClose(day)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(closed ? Color("AppAccent").opacity(0.7) : Color("AppBackground").opacity(0.6))
                    .frame(height: 28)
                    .overlay {
                        if closed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .accessibilityLabel(dayLabel(day, closed: closed))
            }
        }
    }

    private func dayLabel(_ date: Date, closed: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: date)), \(closed ? "closed" : "open")"
    }
}

struct MoodStreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundStyle(Color("AppPrimary"))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) Day Close Streak")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Close the day to keep it")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Spacer()
        }
    }
}
