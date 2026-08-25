import SwiftUI

struct MainTabView: View {
    @ObservedObject var store: DataStore
    @State private var selectedTab: AppTab = .today

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .today:
                    TodayCloseView(store: store)
                case .windDown:
                    BreathingView(store: store)
                case .week:
                    StatisticsView(store: store)
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
    }
}
