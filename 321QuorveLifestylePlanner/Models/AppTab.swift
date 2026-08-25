import Foundation

enum AppTab: Int, CaseIterable, Identifiable {
    case today
    case windDown
    case week
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .windDown: return "Wind-down"
        case .week: return "Week"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .today: return "checkmark.rectangle.fill"
        case .windDown: return "moon.haze.fill"
        case .week: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
}
