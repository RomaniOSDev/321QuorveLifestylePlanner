import Foundation

enum AppTab: Int, CaseIterable, Identifiable {
    case journal
    case breathe
    case stats
    case achievements
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .journal: return "Journal"
        case .breathe: return "Breathe"
        case .stats: return "Stats"
        case .achievements: return "Awards"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .journal: return "book.fill"
        case .breathe: return "wind"
        case .stats: return "chart.xyaxis.line"
        case .achievements: return "medal.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
