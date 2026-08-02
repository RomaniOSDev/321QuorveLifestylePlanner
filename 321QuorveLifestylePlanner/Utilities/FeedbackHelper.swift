import AudioToolbox
import UIKit

enum FeedbackHelper {
    static let soundKey = "quorve_sound_enabled"
    static let hapticsKey = "quorve_haptics_enabled"

    static var isSoundEnabled: Bool {
        if UserDefaults.standard.object(forKey: soundKey) == nil { return true }
        return UserDefaults.standard.bool(forKey: soundKey)
    }

    static var isHapticsEnabled: Bool {
        if UserDefaults.standard.object(forKey: hapticsKey) == nil { return true }
        return UserDefaults.standard.bool(forKey: hapticsKey)
    }

    static func tap() {
        guard isHapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func save() {
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        playSound(1104)
    }

    static func success() {
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        playSound(1057)
    }

    static func sessionComplete() {
        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        playSound(1103)
    }

    static func warning() {
        guard isHapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func achievementUnlocked() {
        if isHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        playSound(1057)
    }

    private static func playSound(_ soundID: SystemSoundID) {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(soundID)
    }

    static func notifySoundPreferenceChanged() {
        NotificationCenter.default.post(name: .feedbackSoundPreferenceChanged, object: nil)
    }
}
