import SwiftUI

struct ScreenBackground<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .ignoresSafeArea()
            }
    }
}

struct ConcentricRingsView: View {
    var body: some View {
        GeometryReader { geo in
            let maxRadius = min(geo.size.width, geo.size.height) * 0.55
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.36)
            Canvas { context, _ in
                for index in 0..<6 {
                    let fraction = CGFloat(index + 1) / 6.0
                    let radius = maxRadius * fraction
                    var path = Path()
                    path.addEllipse(in: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                    context.stroke(
                        path,
                        with: .color(Color("AppAccent").opacity(0.12 + Double(index) * 0.035)),
                        lineWidth: 1.5
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
