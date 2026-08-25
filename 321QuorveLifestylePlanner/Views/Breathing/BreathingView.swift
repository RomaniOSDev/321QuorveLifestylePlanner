import SwiftUI

struct BreathingView: View {
    @ObservedObject var store: DataStore
    @StateObject private var viewModel = BreathingViewModel()
    @StateObject private var focusTimer = FocusTimerViewModel()
    @ObservedObject private var soundscape = SoundscapePlayer.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var mode: PracticeMode = .breathe

    private enum PracticeMode: String, CaseIterable, Identifiable {
        case breathe = "Breathe"
        case focus = "Focus"

        var id: String { rawValue }
    }

    private let presets: [(title: String, inhale: Int, hold: Int, exhale: Int)] = [
        ("4-7-8", 4, 7, 8),
        ("Box", 4, 4, 4),
        ("Calm", 5, 2, 7)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wind-down")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Optional reset after you close the day. A short breath or focus block — not the main loop.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

                Picker("Mode", selection: $mode) {
                    ForEach(PracticeMode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                weeklyGoalCard

                if mode == .breathe {
                    breatheContent
                } else {
                    focusContent
                }

                soundscapeCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .clearScrollBackground()
        .onChange(of: scenePhase) { newPhase in
            viewModel.handleScenePhase(newPhase)
            if newPhase != .active {
                focusTimer.pause()
            }
        }
        .onDisappear {
            if !viewModel.isSessionActive {
                soundscape.stop()
            }
        }
    }

    private var weeklyGoalCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 14) {
                GoalProgressRing(
                    progress: store.weeklyBreathProgress,
                    title: "Weekly wind-down",
                    subtitle: "\(store.weeklyBreathMinutes)/\(store.weeklyBreathGoalMinutes) min this week"
                )

                HStack {
                    Text("Goal")
                        .foregroundStyle(Color("AppTextSecondary"))
                    Spacer()
                    Text("\(store.weeklyBreathGoalMinutes) min")
                        .foregroundStyle(Color("AppAccent"))
                        .fontWeight(.semibold)
                }
                .font(.subheadline)

                Slider(
                    value: Binding(
                        get: { Double(store.weeklyBreathGoalMinutes) },
                        set: { store.updateWeeklyBreathGoal(Int($0)) }
                    ),
                    in: 10...120,
                    step: 5
                )
                .tint(Color("AppPrimary"))
            }
        }
    }

    private var breatheContent: some View {
        VStack(spacing: 24) {
            if !viewModel.isSessionActive && store.sessionsCompleted == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "wind")
                        .font(.system(size: 36))
                        .foregroundStyle(Color("AppAccent"))
                    Text("Use this after a 3-2-1 close, not instead of it.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }

            BreathingOrbView(
                phase: viewModel.phase,
                progress: viewModel.phaseProgress,
                isActive: viewModel.isSessionActive && !viewModel.isPaused,
                onTap: toggleBreathingSession
            )
            .padding(.vertical, 8)

            if viewModel.isSessionActive {
                Text("Cycles: \(viewModel.cyclesCompleted)")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            if viewModel.isPaused {
                Text("Paused — return to continue")
                    .font(.caption)
                    .foregroundStyle(Color("AppAccent"))
            }

            presetsRow
            breathSettingsCard
            sessionButton

            if store.sessionsCompleted > 0 {
                Text("\(store.sessionsCompleted) sessions · \(store.totalMinutesPracticed) min total")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private func toggleBreathingSession() {
        if viewModel.isSessionActive {
            viewModel.stopSession()
        } else {
            viewModel.startSession()
            if FeedbackHelper.isSoundEnabled && !soundscape.isPlaying {
                soundscape.start()
            }
        }
    }

    private var focusContent: some View {
        CalmCard {
            VStack(spacing: 18) {
                Text("Focus Timer")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Focus Mode", selection: Binding(
                    get: { focusTimer.mode },
                    set: { focusTimer.selectMode($0) }
                )) {
                    ForEach(FocusTimerViewModel.Mode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(focusTimer.isRunning)

                ZStack {
                    Circle()
                        .stroke(Color("AppTextSecondary").opacity(0.2), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: focusTimer.progress)
                        .stroke(Color("AppPrimary"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(focusTimer.displayTime)
                        .font(.system(size: 44, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .frame(width: 200, height: 200)
                .padding(.vertical, 8)

                HStack(spacing: 12) {
                    Button {
                        focusTimer.toggle()
                    } label: {
                        Text(focusTimer.isRunning ? "Pause" : "Start")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("AppPrimary"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        focusTimer.reset()
                    } label: {
                        Text("Reset")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("AppSurface"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color("AppAccent").opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                Text("Completed focus blocks: \(focusTimer.completedFocusSessions)")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private var soundscapeCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Soundscape", systemImage: "waveform")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { soundscape.isPlaying },
                        set: { playing in
                            if playing {
                                soundscape.start()
                            } else {
                                soundscape.stop()
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(Color("AppPrimary"))
                    .disabled(!FeedbackHelper.isSoundEnabled)
                }

                if !FeedbackHelper.isSoundEnabled {
                    Text("Enable Sound Effects in Settings to play ambient audio.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                HStack(spacing: 8) {
                    ForEach(SoundscapePlayer.Soundscape.allCases) { item in
                        let selected = soundscape.selectedSoundscape == item
                        Button {
                            FeedbackHelper.tap()
                            soundscape.select(item)
                        } label: {
                            Text(item.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selected ? Color.white : Color("AppTextPrimary"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(selected ? Color("AppPrimary") : Color("AppBackground").opacity(0.5)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var presetsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))

            HStack(spacing: 10) {
                ForEach(presets, id: \.title) { preset in
                    let isSelected =
                        store.breathCycleSettings == [preset.inhale, preset.hold, preset.exhale]
                    Button {
                        FeedbackHelper.tap()
                        store.updateBreathSettings(
                            inhale: preset.inhale,
                            hold: preset.hold,
                            exhale: preset.exhale
                        )
                    } label: {
                        Text(preset.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isSelected ? Color.white : Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color("AppPrimary") : Color("AppSurface"))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSessionActive)
                }
            }
        }
        .opacity(viewModel.isSessionActive ? 0.6 : 1)
    }

    private var breathSettingsCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Breath Cycle")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                breathSlider(
                    title: "Inhale",
                    value: Binding(
                        get: { Double(store.breathCycleSettings[0]) },
                        set: { store.updateBreathSettings(inhale: Int($0), hold: store.breathCycleSettings[1], exhale: store.breathCycleSettings[2]) }
                    ),
                    range: 2...8
                )

                breathSlider(
                    title: "Hold",
                    value: Binding(
                        get: { Double(store.breathCycleSettings[1]) },
                        set: { store.updateBreathSettings(inhale: store.breathCycleSettings[0], hold: Int($0), exhale: store.breathCycleSettings[2]) }
                    ),
                    range: 2...10
                )

                breathSlider(
                    title: "Exhale",
                    value: Binding(
                        get: { Double(store.breathCycleSettings[2]) },
                        set: { store.updateBreathSettings(inhale: store.breathCycleSettings[0], hold: store.breathCycleSettings[1], exhale: Int($0)) }
                    ),
                    range: 2...10
                )
            }
        }
        .disabled(viewModel.isSessionActive)
        .opacity(viewModel.isSessionActive ? 0.6 : 1)
    }

    private func breathSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundStyle(Color("AppTextSecondary"))
                Spacer()
                Text("\(Int(value.wrappedValue))s")
                    .foregroundStyle(Color("AppAccent"))
                    .fontWeight(.semibold)
            }
            Slider(value: value, in: range, step: 1)
                .tint(Color("AppPrimary"))
        }
    }

    private var sessionButton: some View {
        Button {
            toggleBreathingSession()
        } label: {
            Text(viewModel.isSessionActive ? "End Session" : "Start Session")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(viewModel.isSessionActive ? Color("AppSurface") : Color("AppPrimary"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(viewModel.isSessionActive ? Color("AppAccent") : Color.clear, lineWidth: 1.5)
                        )
                )
        }
        .accessibilityIdentifier("breathing_session_button")
    }
}
