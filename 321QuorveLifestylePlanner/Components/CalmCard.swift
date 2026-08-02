import SwiftUI

struct CalmCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color("AppSurface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color("AppAccent").opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: Color("AppPrimary").opacity(0.18), radius: 18, y: 8)
            )
    }
}

struct SoftCapsuleTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    KeyboardDismiss.resign()
                    FeedbackHelper.tap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: selection == tab ? 14 : 15, weight: .semibold))
                        if selection == tab {
                            Text(tab.title)
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }
                    }
                    .foregroundStyle(selection == tab ? Color.white : Color("AppTextSecondary"))
                    .padding(.horizontal, selection == tab ? 10 : 8)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(selection == tab ? Color("AppPrimary") : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
            }
        }
        .padding(5)
        .background(
            Capsule()
                .fill(Color("AppSurface"))
                .shadow(color: Color.black.opacity(0.25), radius: 14, y: 6)
        )
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Color("AppBackground").ignoresSafeArea(edges: .bottom))
    }
}
