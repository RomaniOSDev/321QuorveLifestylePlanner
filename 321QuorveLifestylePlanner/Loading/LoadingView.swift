import SwiftUI

struct LoadingAmbientField: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            Color.appBackground

            RadialGradient(
                colors: [
                    Color.appPrimary.opacity(0.34),
                    Color.appAccent.opacity(0.12),
                    Color.appBackground.opacity(0.2),
                    Color.appBackground
                ],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 20,
                endRadius: 420
            )

            Circle()
                .fill(Color.appPrimary.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: drift ? 36 : -28, y: drift ? -90 : -60)

            Circle()
                .fill(Color.appAccent.opacity(0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 64)
                .offset(x: drift ? -50 : 40, y: drift ? 180 : 140)

            Circle()
                .fill(Color.appSurface.opacity(0.55))
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .offset(x: 110, y: -220)

            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(Color.appAccent.opacity(index.isMultiple(of: 2) ? 0.35 : 0.18))
                    .frame(width: CGFloat(2 + index % 3), height: CGFloat(2 + index % 3))
                    .offset(
                        x: particleX(index),
                        y: particleY(index) + (drift ? -10 : 10)
                    )
                    .blur(radius: index % 3 == 0 ? 0.5 : 0)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func particleX(_ index: Int) -> CGFloat {
        let values: [CGFloat] = [-130, -90, -40, 20, 70, 120, -150, 150, -20, 95, -70, 40]
        return values[index % values.count]
    }

    private func particleY(_ index: Int) -> CGFloat {
        let values: [CGFloat] = [-210, -150, -80, -20, 40, 110, 170, -250, 200, -120, 70, -40]
        return values[index % values.count]
    }
}

struct LoadingOrbitRings: View {
    @State private var spinOuter: Double = 0
    @State private var spinInner: Double = 0
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.55),
                            Color.appAccent.opacity(0.15),
                            Color.appPrimary.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 1.2, dash: [5, 8])
                )
                .frame(width: 268, height: 268)
                .rotationEffect(.degrees(spinOuter))
                .scaleEffect(breathe ? 1.03 : 0.97)

            Circle()
                .trim(from: 0.08, to: 0.72)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.appPrimary.opacity(0.05),
                            Color.appPrimary,
                            Color.appAccent,
                            Color.appPrimary.opacity(0.05)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 236, height: 236)
                .rotationEffect(.degrees(spinInner))

            Circle()
                .stroke(Color.appSurface.opacity(0.55), lineWidth: 1)
                .frame(width: 204, height: 204)
        }
        .onAppear {
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                spinOuter = 360
            }
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                spinInner = 360
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

struct LoadingHeroCard: View {
    @State private var glow = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.92),
                            Color.appBackground.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.appPrimary.opacity(0.7),
                                    Color.appAccent.opacity(0.25),
                                    Color.appPrimary.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.appPrimary.opacity(glow ? 0.45 : 0.22), radius: glow ? 28 : 16, y: 10)

            Image("LoadingArt")
                .resizable()
                .scaledToFit()
                .padding(18)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .frame(width: 292, height: 292)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

struct LoadingProgressBar: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appSurface.opacity(0.75))
                    .overlay(
                        Capsule()
                            .stroke(Color.appAccent.opacity(0.18), lineWidth: 1)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent, Color.appPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 0.42)
                    .offset(x: phase * (width * 0.58))
                    .shadow(color: Color.appPrimary.opacity(0.55), radius: 8, y: 0)
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

struct LoadingStatusLine: View {
    @State private var step = 0

    private let lines = [
        "Preparing your evening close",
        "Aligning tomorrow's move",
        "Almost ready"
    ]

    var body: some View {
        Text(lines[step % lines.count])
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(Color.appTextSecondary)
            .multilineTextAlignment(.center)
            .id(step)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        step = (step + 1) % lines.count
                    }
                }
            }
    }
}

struct LoadingView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            LoadingAmbientField()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack {
                    LoadingOrbitRings()
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.88)

                    LoadingHeroCard()
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)
                        .offset(y: appeared ? 0 : 18)
                }
                .frame(height: 320)

                VStack(spacing: 16) {
                    LoadingProgressBar()
                        .frame(width: 168)
                        .opacity(appeared ? 1 : 0)

                    LoadingStatusLine()
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.top, 34)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }
}

#Preview {
    LoadingView()
}
