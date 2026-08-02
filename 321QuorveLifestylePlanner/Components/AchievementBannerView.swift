import SwiftUI

struct AchievementBannerView: View {
    let achievement: AchievementDefinition
    let onDismiss: () -> Void

    @State private var offset: CGFloat = -120

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image("DecorBadge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievement Unlocked")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                    Text(achievement.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("AppSurface"))
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
            .offset(y: offset)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    offset = 12
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        offset = -120
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onDismiss()
                    }
                }
            }

            Spacer()
        }
    }
}
