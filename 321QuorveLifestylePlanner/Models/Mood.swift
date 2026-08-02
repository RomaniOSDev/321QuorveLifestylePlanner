import Foundation

struct Mood: Codable, Identifiable, Equatable {
    let id: UUID
    var emoji: String
    var date: Date
    var note: String
    var tags: [String]

    init(
        id: UUID = UUID(),
        emoji: String,
        date: Date = Date(),
        note: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.emoji = emoji
        self.date = date
        self.note = note
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id, emoji, date, note, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        emoji = try container.decode(String.self, forKey: .emoji)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

enum MoodTag: String, CaseIterable, Identifiable {
    case sleep = "Sleep"
    case work = "Work"
    case sport = "Sport"
    case social = "Social"
    case health = "Health"
    case nature = "Nature"
    case food = "Food"
    case study = "Study"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .work: return "briefcase.fill"
        case .sport: return "figure.run"
        case .social: return "person.2.fill"
        case .health: return "heart.fill"
        case .nature: return "leaf.fill"
        case .food: return "fork.knife"
        case .study: return "book.fill"
        }
    }
}
