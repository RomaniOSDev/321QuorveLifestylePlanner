import StoreKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: DataStore

    @AppStorage(FeedbackHelper.soundKey) private var soundEnabled = true
    @AppStorage(FeedbackHelper.hapticsKey) private var hapticsEnabled = true
    @AppStorage(ReminderService.enabledKey) private var reminderEnabled = false
    @AppStorage(AppThemePreference.storageKey) private var themeRaw = AppThemePreference.dark.rawValue

    @State private var showResetAlert = false
    @State private var reminderDeniedHint = false

    private var themeBinding: Binding<AppThemePreference> {
        Binding(
            get: { AppThemePreference(rawValue: themeRaw) ?? .dark },
            set: { themeRaw = $0.rawValue }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsCard
                preferencesCard
                themeCard
                reminderCard

                settingsRow(title: "Rate Us", icon: "star.fill") {
                    FeedbackHelper.tap()
                    rateApp()
                }
                .accessibilityIdentifier("settings_rate_us")

                settingsRow(title: "Privacy Policy", icon: "hand.raised.fill") {
                    FeedbackHelper.tap()
                    UIApplication.shared.open(AppLink.privacy)
                }
                .accessibilityIdentifier("settings_privacy")

                settingsRow(title: "Support", icon: "questionmark.circle.fill") {
                    FeedbackHelper.tap()
                    UIApplication.shared.open(AppLink.support)
                }
                .accessibilityIdentifier("settings_support")

                Button {
                    FeedbackHelper.tap()
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Reset All Data")
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundStyle(.red)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color("AppSurface"))
                    )
                }
                .accessibilityIdentifier("settings_reset")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetAll()
            }
        } message: {
            Text("This will permanently delete all journal entries, habits, and progress.")
        }
        .alert("Notifications Disabled", isPresented: $reminderDeniedHint) {
            Button("OK", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Enable notifications in Settings to receive a daily journal reminder.")
        }
    }

    private var statsCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Stats")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Text("See Charts tab")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                statRow(label: "Journal Entries", value: "\(store.entriesCreated)")
                statRow(label: "Breathing Sessions", value: "\(store.sessionsCompleted)")
                statRow(label: "Current Streak", value: "\(store.streakDays) days")
                statRow(label: "Minutes Practiced", value: "\(store.totalMinutesPracticed)")
            }
        }
    }

    private var preferencesCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Preferences")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Toggle(isOn: $soundEnabled) {
                    Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .tint(Color("AppPrimary"))
                .accessibilityIdentifier("settings_sound_toggle")
                .onChange(of: soundEnabled) { _ in
                    FeedbackHelper.notifySoundPreferenceChanged()
                    FeedbackHelper.tap()
                }

                Toggle(isOn: $hapticsEnabled) {
                    Label("Haptic Feedback", systemImage: "hand.tap.fill")
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .tint(Color("AppPrimary"))
                .accessibilityIdentifier("settings_haptics_toggle")
                .onChange(of: hapticsEnabled) { enabled in
                    if enabled {
                        FeedbackHelper.tap()
                    }
                }

                Text("When sound is off, every system sound and soundscape in the app is muted.")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private var themeCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Picker("Theme", selection: themeBinding) {
                    ForEach(AppThemePreference.allCases) { preference in
                        Text(preference.title).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: themeRaw) { _ in
                    FeedbackHelper.tap()
                }
            }
        }
    }

    private var reminderCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily Reminder")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Toggle(isOn: Binding(
                    get: { reminderEnabled },
                    set: { newValue in
                        Task {
                            await ReminderService.setEnabled(newValue)
                            await MainActor.run {
                                reminderEnabled = ReminderService.isEnabled
                                if newValue && !ReminderService.isEnabled {
                                    reminderDeniedHint = true
                                }
                            }
                        }
                    }
                )) {
                    Label("Journal at 8:00 PM", systemImage: "bell.fill")
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .tint(Color("AppPrimary"))
                .accessibilityIdentifier("settings_reminder_toggle")

                Text("A gentle nudge to log your mood and habits.")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
            Text(value)
                .foregroundStyle(Color("AppAccent"))
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func settingsRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color("AppPrimary"))
                    .frame(width: 28)
                Text(title)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("AppSurface"))
            )
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
