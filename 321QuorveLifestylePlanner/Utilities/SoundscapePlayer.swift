import AVFoundation
import Combine
import Foundation

private final class SoundscapeOscillatorState: @unchecked Sendable {
    var phase: Double = 0
    var phase2: Double = 0
    var frequency1: Double = 110
    var frequency2: Double = 165
}

@MainActor
final class SoundscapePlayer: ObservableObject {
    static let shared = SoundscapePlayer()

    @Published var isPlaying = false
    @Published var selectedSoundscape: Soundscape = .ocean

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private let oscillator = SoundscapeOscillatorState()

    enum Soundscape: String, CaseIterable, Identifiable {
        case ocean
        case forest
        case softDrone

        var id: String { rawValue }

        var title: String {
            switch self {
            case .ocean: return "Ocean"
            case .forest: return "Forest"
            case .softDrone: return "Soft Drone"
            }
        }

        var frequencies: (Double, Double) {
            switch self {
            case .ocean: return (110, 165)
            case .forest: return (196, 247)
            case .softDrone: return (87, 130.5)
            }
        }
    }

    private init() {
        NotificationCenter.default.addObserver(
            forName: .feedbackSoundPreferenceChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMuteChange()
            }
        }
    }

    func start() {
        guard FeedbackHelper.isSoundEnabled else {
            stop()
            return
        }
        stopEngine()
        configureAudioSession()

        let freqs = selectedSoundscape.frequencies
        oscillator.phase = 0
        oscillator.phase2 = 0
        oscillator.frequency1 = freqs.0
        oscillator.frequency2 = freqs.1

        let engine = AVAudioEngine()
        let state = oscillator
        let sampleRate = 44100.0

        let source = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frames = Int(frameCount)
            for buffer in ablPointer {
                guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                for frame in 0..<frames {
                    let sample =
                        0.045 * sin(state.phase) +
                        0.03 * sin(state.phase2) +
                        0.008 * Double.random(in: -1...1)
                    data[frame] = Float(sample)
                    state.phase += 2 * Double.pi * state.frequency1 / sampleRate
                    state.phase2 += 2 * Double.pi * state.frequency2 / sampleRate
                    if state.phase > 2 * Double.pi { state.phase -= 2 * Double.pi }
                    if state.phase2 > 2 * Double.pi { state.phase2 -= 2 * Double.pi }
                }
            }
            return noErr
        }

        engine.attach(source)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(source, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.55

        do {
            try engine.start()
            self.engine = engine
            self.sourceNode = source
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        stopEngine()
        isPlaying = false
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func select(_ soundscape: Soundscape) {
        selectedSoundscape = soundscape
        if isPlaying {
            start()
        }
    }

    private func handleMuteChange() {
        if !FeedbackHelper.isSoundEnabled {
            stop()
        }
    }

    private func stopEngine() {
        engine?.stop()
        if let sourceNode {
            engine?.detach(sourceNode)
        }
        engine = nil
        sourceNode = nil
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
