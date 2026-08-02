import Foundation

enum DailyQuotes {
    static let all: [String] = [
        "Breathe. You are exactly where you need to be.",
        "Small calm moments build a steady life.",
        "Your feelings are valid — notice them gently.",
        "Progress is quiet. Keep showing up.",
        "One mindful breath can change the hour.",
        "Rest is productive. Softness is strength.",
        "You do not have to rush your healing.",
        "Gratitude turns ordinary days into gifts.",
        "Be kind to the person you are becoming.",
        "Presence is the most generous gift you give yourself.",
        "Let today be enough.",
        "Calm is a skill you can practice.",
        "Your pace is allowed to be human.",
        "Choose curiosity over judgment today.",
        "A clear mind begins with a soft exhale.",
        "You are allowed to begin again.",
        "Joy often hides in simple routines.",
        "Listen inward before you push outward.",
        "Steady effort beats perfect intention.",
        "Make room for stillness — it restores you.",
        "Your journal is a safe place for truth.",
        "Gentle consistency creates lasting change.",
        "Honor both your energy and your limits.",
        "Peace grows where attention rests.",
        "Today, choose one kind action for yourself.",
        "The body remembers calm — invite it back.",
        "You can hold hard feelings and still move forward.",
        "Silence can be a teacher.",
        "Celebrate the quiet wins.",
        "Return to breath whenever the mind races.",
        "Enough for today is still enough."
    ]

    static func quote(for date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return all[(day - 1) % all.count]
    }
}
