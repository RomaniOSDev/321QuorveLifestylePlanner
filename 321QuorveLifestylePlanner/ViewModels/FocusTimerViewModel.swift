import Combine
import Foundation
import SwiftUI

@MainActor
final class FocusTimerViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case focus = "Focus"
        case shortBreak = "Break"

        var id: String { rawValue }

        var defaultMinutes: Int {
            switch self {
            case .focus: return 25
            case .shortBreak: return 5
            }
        }
    }

    @Published var mode: Mode = .focus
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning = false
    @Published var completedFocusSessions = 0

    private var timerCancellable: AnyCancellable?
    private var endDate: Date?

    func selectMode(_ mode: Mode) {
        guard !isRunning else { return }
        self.mode = mode
        remainingSeconds = mode.defaultMinutes * 60
    }

    func start() {
        guard !isRunning else { return }
        FeedbackHelper.save()
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        timerCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        guard isRunning else { return }
        tick()
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
        endDate = nil
    }

    func reset() {
        pause()
        remainingSeconds = mode.defaultMinutes * 60
    }

    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    var displayTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        let total = Double(mode.defaultMinutes * 60)
        guard total > 0 else { return 0 }
        return 1 - (Double(remainingSeconds) / total)
    }

    private func tick() {
        guard let endDate else { return }
        let left = max(Int(ceil(endDate.timeIntervalSinceNow)), 0)
        remainingSeconds = left
        if left == 0 {
            complete()
        }
    }

    private func complete() {
        pause()
        remainingSeconds = 0
        if mode == .focus {
            completedFocusSessions += 1
        }
        FeedbackHelper.sessionComplete()
        remainingSeconds = mode.defaultMinutes * 60
    }
}
