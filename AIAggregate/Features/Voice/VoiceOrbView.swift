import SwiftUI

struct VoiceOrbView: View {
    var level: CGFloat
    var state: VoiceCallState

    @State private var phase: CGFloat = 0
    @State private var breathe: CGFloat = 1

    var body: some View {
        ZStack {
            // outer glow
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 220, height: 220)
                .scaleEffect(breathe * (1 + level * 0.25))
                .blur(radius: 24)

            // glass ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), accent.opacity(0.35), Color.white.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .frame(width: 168, height: 168)
                .scaleEffect(1 + level * 0.12)

            // core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.95), accent, accent.opacity(0.75)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 90
                    )
                )
                .frame(width: 150, height: 150)
                .scaleEffect(breathe * (1 + level * 0.2))
                .shadow(color: accent.opacity(0.45), radius: 24, y: 8)

            // soft specular
            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 60, height: 36)
                .offset(x: -20, y: -36)
                .blur(radius: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = 1.05
            }
        }
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.7), value: level)
    }

    private var accent: Color {
        switch state {
        case .listening, .recognizing: return Color.blue
        case .thinking: return Color.indigo
        case .speaking: return Color.purple
        case .muted: return Color.gray
        case .error: return Color.red
        default: return Color.blue
        }
    }
}
