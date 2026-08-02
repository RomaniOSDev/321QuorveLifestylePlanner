import Combine
import Foundation
import SwiftUI

@MainActor
final class BreathingViewModel: ObservableObject {
    @Published var phase: BreathingPhase = .idle
    @Published var phaseProgress: Double = 0
    @Published var isSessionActive = false
    @Published var isPaused = false
    @Published var cyclesCompleted = 0

    private var phaseStartDate: Date?
    private var pauseBegan: Date?
    private var phasePausedAccumulated: TimeInterval = 0
    private var sessionStartDate: Date?
    private var sessionPausedAccumulated: TimeInterval = 0
    private var timerCancellable: AnyCancellable?

    var inhaleDuration: Int { store.breathCycleSettings[0] }
    var holdDuration: Int { store.breathCycleSettings[1] }
    var exhaleDuration: Int { store.breathCycleSettings[2] }

    private let store: DataStore

    init(store: DataStore? = nil) {
        self.store = store ?? .shared
    }

    func startSession() {
        guard !isSessionActive else { return }
        FeedbackHelper.save()
        isSessionActive = true
        isPaused = false
        cyclesCompleted = 0
        phase = .inhale
        phaseProgress = 0
        sessionStartDate = Date()
        phaseStartDate = Date()
        phasePausedAccumulated = 0
        sessionPausedAccumulated = 0
        startTimer()
    }

    func stopSession() {
        guard isSessionActive else { return }
        let minutes = sessionMinutes()
        isSessionActive = false
        isPaused = false
        phase = .idle
        phaseProgress = 0
        timerCancellable?.cancel()
        timerCancellable = nil
        if minutes > 0 || cyclesCompleted > 0 {
            store.completeBreathingSession(minutes: max(minutes, 1), cycles: cyclesCompleted)
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            resumeIfNeeded()
        case .inactive, .background:
            pauseIfNeeded()
        @unknown default:
            break
        }
    }

    private func pauseIfNeeded() {
        guard isSessionActive, !isPaused else { return }
        isPaused = true
        pauseBegan = Date()
        timerCancellable?.cancel()
    }

    private func resumeIfNeeded() {
        guard isSessionActive, isPaused, let pauseBegan else { return }
        let pauseDuration = Date().timeIntervalSince(pauseBegan)
        phasePausedAccumulated += pauseDuration
        sessionPausedAccumulated += pauseDuration
        self.pauseBegan = nil
        isPaused = false
        startTimer()
    }

    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isSessionActive, !isPaused, let phaseStartDate else { return }

        let elapsed = Date().timeIntervalSince(phaseStartDate) - phasePausedAccumulated
        let duration = currentPhaseDuration()
        let progress = min(max(elapsed / duration, 0), 1)
        phaseProgress = progress

        if elapsed >= duration {
            advancePhase()
        }
    }

    private func currentPhaseDuration() -> TimeInterval {
        switch phase {
        case .inhale: return TimeInterval(inhaleDuration)
        case .hold: return TimeInterval(holdDuration)
        case .exhale: return TimeInterval(exhaleDuration)
        case .idle: return 1
        }
    }

    private func advancePhase() {
        phaseStartDate = Date()
        phasePausedAccumulated = 0
        phaseProgress = 0

        switch phase {
        case .inhale:
            phase = .hold
        case .hold:
            phase = .exhale
        case .exhale:
            cyclesCompleted += 1
            phase = .inhale
        case .idle:
            break
        }
    }

    private func sessionMinutes() -> Int {
        guard let sessionStartDate else { return 0 }
        let seconds = Date().timeIntervalSince(sessionStartDate) - sessionPausedAccumulated
        return max(Int(seconds / 60), 0)
    }
}
