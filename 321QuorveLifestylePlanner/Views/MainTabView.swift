import SwiftUI

struct MainTabView: View {
    @ObservedObject var store: DataStore
    @State private var selectedTab: AppTab = .journal

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .journal:
                    JournalView(store: store)
                case .breathe:
                    BreathingView(store: store)
                case .stats:
                    StatisticsView(store: store)
                case .achievements:
                    AchievementsView(store: store)
                case .settings:
                    SettingsView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dismissKeyboardOnTap()

            SoftCapsuleTabBar(selection: $selectedTab)
        }
        .background {
            Color("AppBackground")
                .overlay {
                    Image("HeroBackground")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.5)
                }
                .overlay {
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(0.3),
                            Color("AppBackground").opacity(0.1),
                            Color("AppBackground").opacity(0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipped()
                .ignoresSafeArea()
        }
        .ignoresSafeArea(.keyboard)
        .overlay(alignment: .top) {
            if let achievement = store.pendingAchievementBanner {
                AchievementBannerView(achievement: achievement) {
                    store.dismissAchievementBanner()
                }
            }
        }
    }
}
