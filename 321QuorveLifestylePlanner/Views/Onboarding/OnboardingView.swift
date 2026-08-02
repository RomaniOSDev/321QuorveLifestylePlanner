import SwiftUI

struct OnboardingPage: Identifiable {
    let id: Int
    let headline: String
    let description: String
    let symbol: String
}

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var pageIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            headline: "Find Inner Calm",
            description: "Use the app to enhance mindfulness and emotional well-being.",
            symbol: "circle.circle"
        ),
        OnboardingPage(
            id: 1,
            headline: "Document Feelings",
            description: "Capture your daily emotions with the journal feature.",
            symbol: "heart.text.square"
        ),
        OnboardingPage(
            id: 2,
            headline: "Start Your Journey",
            description: "Begin by writing your first journal entry today.",
            symbol: "pencil.and.outline"
        )
    ]

    var body: some View {
        ScreenBackground {
            VStack(spacing: 28) {
                Spacer()

                OnboardingIllustration(symbol: pages[pageIndex].symbol)
                    .id(pageIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                VStack(spacing: 12) {
                    Text(pages[pageIndex].headline)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .multilineTextAlignment(.center)

                    Text(pages[pageIndex].description)
                        .font(.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .id("text_\(pageIndex)")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == pageIndex ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.4))
                            .frame(width: index == pageIndex ? 10 : 7, height: index == pageIndex ? 10 : 7)
                            .animation(.spring(response: 0.35), value: pageIndex)
                    }
                }

                Button {
                    FeedbackHelper.tap()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        if pageIndex < pages.count - 1 {
                            pageIndex += 1
                        } else {
                            onComplete()
                        }
                    }
                } label: {
                    Text(pageIndex < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color("AppPrimary"))
                        )
                }
                .padding(.horizontal, 32)
                .accessibilityIdentifier("onboarding_next_button")

                Spacer(minLength: 40)
            }
        }
    }
}

private struct OnboardingIllustration: View {
    let symbol: String
    @State private var appeared = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color("AppAccent").opacity(0.25), lineWidth: 2)
                    .frame(width: CGFloat(100 + index * 44), height: CGFloat(100 + index * 44))
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.08), value: appeared)
            }

            Image(systemName: symbol)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color("AppAccent"))
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
        }
        .frame(width: 220, height: 220)
        .onAppear {
            appeared = true
        }
        .onDisappear {
            appeared = false
        }
    }
}
