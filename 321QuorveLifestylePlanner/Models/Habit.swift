import Foundation

struct Habit: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var isCompleted: Bool
    var date: Date
    var note: String

    init(
        id: UUID = UUID(),
        name: String,
        isCompleted: Bool = false,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.date = date
        self.note = note
    }

    enum CodingKeys: String, CodingKey {
        case id, name, isCompleted, date, note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}
