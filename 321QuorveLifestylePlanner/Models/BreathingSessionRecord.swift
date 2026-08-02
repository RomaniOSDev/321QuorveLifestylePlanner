import Foundation

struct BreathingSessionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let minutes: Int
    let cycles: Int

    init(id: UUID = UUID(), date: Date = Date(), minutes: Int, cycles: Int) {
        self.id = id
        self.date = date
        self.minutes = minutes
        self.cycles = cycles
    }
}
