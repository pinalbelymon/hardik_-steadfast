import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct MilestoneCelebrationView: View {
    let milestone: Milestone
    let onContinue: () -> Void

    @State private var backdropVisible = false
    @State private var badgeScale: CGFloat = 0.2
    @State private var badgeRotation: Double = -18
    @State private var raysSpin = false
    @State private var contentVisible = false
    @State private var treeVisible = false
    @State private var confettiBurst = false
    @State private var shimmer = false
    @State private var buttonVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(backdropVisible ? 0.82 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.35), value: backdropVisible)

            MilestoneConfettiView(isActive: confettiBurst)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    unlockLabel
                    badgeSection
                    titleSection
                    treeSection
                }
                .padding(.horizontal, 28)
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 30)

                Spacer()

                continueButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 44)
                    .opacity(buttonVisible ? 1 : 0)
                    .offset(y: buttonVisible ? 0 : 24)
            }
        }
        .onAppear { runCelebrationSequence() }
    }

    private var unlockLabel: some View {
        VStack(spacing: 8) {
            Text(L("celebration.unlocked"))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2.5)
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Theme.accent.opacity(0.14), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.accent.opacity(shimmer ? 0.7 : 0.25), lineWidth: 1)
                )

            Text(L("celebration.achievement_earned"))
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private var badgeSection: some View {
        ZStack {
            rotatingRays
                .frame(width: 240, height: 240)
                .opacity(raysSpin ? 1 : 0)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.accent.opacity(0.35), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(shimmer ? 1.08 : 0.92)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: shimmer)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accent.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 118, height: 118)
                    .shadow(color: Theme.accent.opacity(0.55), radius: 24, y: 10)

                Circle()
                    .stroke(.white.opacity(0.35), lineWidth: 3)
                    .frame(width: 118, height: 118)

                Image(systemName: milestone.icon)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: badgeScale)
            }
            .scaleEffect(badgeScale)
            .rotationEffect(.degrees(badgeRotation))
        }
        .frame(height: 240)
    }

    private var rotatingRays: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.45), Theme.accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 5, height: 92)
                    .offset(y: -46)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
        .rotationEffect(.degrees(raysSpin ? 360 : 0))
        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: raysSpin)
    }

    private var titleSection: some View {
        VStack(spacing: 10) {
            Text(milestone.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(L("celebration.day_streak", milestone.day))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.accent)

            Text(milestone.celebrationSubtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var treeSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.08))
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
                )

            HStack(spacing: 16) {
                Image(milestone.treeStage.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 12, y: 6)
                    .scaleEffect(treeVisible ? 1 : 0.5)
                    .rotationEffect(.degrees(treeVisible ? 0 : -8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("celebration.tree_evolved"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                    Text(milestone.treeStage.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(L("celebration.keep_growing"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 18)
        }
        .scaleEffect(treeVisible ? 1 : 0.85)
        .opacity(treeVisible ? 1 : 0)
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text(L("common.continue"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [Theme.accent, Theme.accent.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .shadow(color: Theme.accent.opacity(0.45), radius: 16, y: 8)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func runCelebrationSequence() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        #endif

        backdropVisible = true

        withAnimation(.spring(response: 0.55, dampingFraction: 0.58)) {
            badgeScale = 1
            badgeRotation = 0
        }

        withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.12)) {
            contentVisible = true
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.78).delay(0.35)) {
            treeVisible = true
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.75)) {
            buttonVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            raysSpin = true
            shimmer = true
            confettiBurst = true
        }
    }
}

private struct MilestoneConfettiView: View {
    let isActive: Bool

    private let particles: [ConfettiParticle] = (0..<48).map { index in
        ConfettiParticle(
            id: index,
            x: Double.random(in: 0.05...0.95),
            delay: Double.random(in: 0...0.45),
            duration: Double.random(in: 1.8...3.2),
            size: CGFloat.random(in: 6...12),
            rotation: Double.random(in: 0...360),
            color: [Theme.accent, Color.yellow, Color.orange, Color.white, Theme.flower][index % 5]
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle, width: geo.size.width, height: geo.size.height, isActive: isActive)
                }
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    let x: Double
    let delay: Double
    let duration: Double
    let size: CGFloat
    let rotation: Double
    let color: Color
}

private struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let width: CGFloat
    let height: CGFloat
    let isActive: Bool

    @State private var fall = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.4)
            .rotationEffect(.degrees(fall ? particle.rotation + 280 : particle.rotation))
            .position(
                x: particle.x * width,
                y: fall ? height + 20 : -20
            )
            .opacity(isActive ? 1 : 0)
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeIn(duration: particle.duration).delay(particle.delay)) {
                    fall = true
                }
            }
            .onChange(of: isActive) { _, active in
                guard active else { return }
                withAnimation(.easeIn(duration: particle.duration).delay(particle.delay)) {
                    fall = true
                }
            }
    }
}
