import Foundation

enum MoveSlot: String, Codable, CaseIterable, Identifiable {
    case morning
    case midday
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .evening: return "Evening"
        }
    }

    var defaultHour: Int {
        switch self {
        case .morning: return 7
        case .midday: return 12
        case .evening: return 19
        }
    }

    var defaultMinute: Int {
        switch self {
        case .morning: return 30
        case .midday: return 30
        case .evening: return 0
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .midday: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }
}

enum DrainTag: String, CaseIterable, Identifiable {
    case work = "Work"
    case people = "People"
    case sleep = "Sleep"
    case delay = "Delay"
    case health = "Health"
    case home = "Home"
    case money = "Money"
    case screen = "Screen"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .people: return "person.2.fill"
        case .sleep: return "moon.fill"
        case .delay: return "hourglass"
        case .health: return "heart.fill"
        case .home: return "house.fill"
        case .money: return "creditcard.fill"
        case .screen: return "iphone"
        }
    }

    static func suggestedSlot(from tags: [String]) -> MoveSlot {
        if tags.contains(DrainTag.sleep.rawValue) || tags.contains(DrainTag.delay.rawValue) {
            return .morning
        }
        if tags.contains(DrainTag.work.rawValue) || tags.contains(DrainTag.screen.rawValue) {
            return .evening
        }
        return .midday
    }
}

struct DayClose: Codable, Identifiable, Equatable {
    let id: UUID
    var date: Date
    var wins: [String]
    var drains: [String]
    var drainTags: [String]
    var moveTitle: String
    var moveSlot: MoveSlot
    var moveHour: Int
    var moveMinute: Int
    var isMoveDone: Bool
    var closedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        wins: [String] = ["", "", ""],
        drains: [String] = ["", ""],
        drainTags: [String] = [],
        moveTitle: String = "",
        moveSlot: MoveSlot = .morning,
        moveHour: Int = MoveSlot.morning.defaultHour,
        moveMinute: Int = MoveSlot.morning.defaultMinute,
        isMoveDone: Bool = false,
        closedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.wins = Self.padded(wins, count: 3)
        self.drains = Self.padded(drains, count: 2)
        self.drainTags = drainTags
        self.moveTitle = moveTitle
        self.moveSlot = moveSlot
        self.moveHour = moveHour
        self.moveMinute = moveMinute
        self.isMoveDone = isMoveDone
        self.closedAt = closedAt
    }

    var moveTimeLabel: String {
        String(format: "%d:%02d", moveHour, moveMinute)
    }

    var filledWins: [String] {
        wins.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    var filledDrains: [String] {
        drains.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    var isComplete: Bool {
        filledWins.count == 3
            && filledDrains.count == 2
            && !moveTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func padded(_ values: [String], count: Int) -> [String] {
        var result = values
        while result.count < count { result.append("") }
        if result.count > count { result = Array(result.prefix(count)) }
        return result
    }
}
