import SwiftUI

struct BreathingOrbView: View {
    let phase: BreathingPhase
    let progress: Double
    let isActive: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            FeedbackHelper.tap()
            onTap?()
        } label: {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { _ in
                ZStack {
                    ForEach(0..<4, id: \.self) { ring in
                        Circle()
                            .stroke(Color("AppAccent").opacity(0.12 - Double(ring) * 0.02), lineWidth: 1.5)
                            .scaleEffect(orbScale + CGFloat(ring) * 0.08)
                    }

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("AppPrimary").opacity(0.85),
                                    Color("AppAccent").opacity(0.45),
                                    Color("AppSurface").opacity(0.2)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 140
                            )
                        )
                        .scaleEffect(orbScale)
                        .shadow(color: Color("AppPrimary").opacity(0.35), radius: 24, x: 0, y: 8)

                    VStack(spacing: 6) {
                        Text(phase.label)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(phase.instruction)
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                .frame(width: 260, height: 260)
                .frame(width: 340, height: 340)
                .contentShape(Circle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isActive ? "End Session" : "Start Session")
        .accessibilityIdentifier("breathing_orb_button")
    }

    private var orbScale: CGFloat {
        let base: CGFloat = 0.55
        let range: CGFloat = 0.45
        switch phase {
        case .inhale:
            return base + range * CGFloat(progress)
        case .hold:
            return base + range
        case .exhale:
            return base + range * CGFloat(1.0 - progress)
        case .idle:
            return base + range * 0.3
        }
    }
}

enum BreathingPhase: Equatable {
    case idle
    case inhale
    case hold
    case exhale

    var label: String {
        switch self {
        case .idle: return "Ready"
        case .inhale: return "Inhale"
        case .hold: return "Hold"
        case .exhale: return "Exhale"
        }
    }

    var instruction: String {
        switch self {
        case .idle: return "Tap to start"
        case .inhale: return "Breathe in slowly"
        case .hold: return "Hold gently"
        case .exhale: return "Release slowly"
        }
    }
}
