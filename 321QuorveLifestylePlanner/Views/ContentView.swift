import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore.shared
    @AppStorage(AppThemePreference.storageKey) private var themeRaw = AppThemePreference.dark.rawValue

    private var theme: AppThemePreference {
        AppThemePreference(rawValue: themeRaw) ?? .dark
    }

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView(store: store)
            } else {
                OnboardingView {
                    store.completeOnboarding()
                }
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .tint(Color("AppPrimary"))
    }
}
