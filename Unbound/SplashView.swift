import SwiftUI

enum AppBranding {
    static let name = "Steadfast"
    static let tagline = "Recovery & Focus"
    static let fullName = "Steadfast: Recovery & Focus"
    static let motto = "One day at a time."

    /// Set your App Store ID before App Store release.
    static let appStoreID = "6799915361"

    static var writeReviewURL: URL? {
        guard !appStoreID.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }
}

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    let onFinished: () -> Void

    @State private var ringPulse = false
    @State private var iconVisible = false
    @State private var titleVisible = false
    @State private var taglineVisible = false
    @State private var mottoVisible = false
    @State private var exitSplash = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 28) {
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Theme.accent.opacity(ringPulse ? 0.08 : 0.22), lineWidth: 2)
                            .frame(width: ringSize(index), height: ringSize(index))
                            .scaleEffect(ringPulse ? 1.06 : 0.94)
                            .animation(
                                .easeInOut(duration: 1.8)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: ringPulse
                            )
                    }

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.accent,
                                        Theme.accent.opacity(colorScheme == .dark ? 0.72 : 0.82)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 108, height: 108)
                            .shadow(color: Theme.accent.opacity(0.35), radius: 20, y: 10)

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundStyle(.white)
                            .symbolEffect(.bounce, value: iconVisible)
                    }
                    .scaleEffect(iconVisible ? 1 : 0.35)
                    .opacity(iconVisible ? 1 : 0)
                }
                .frame(height: 240)

                VStack(spacing: 10) {
                    Text(L("branding.name"))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .opacity(titleVisible ? 1 : 0)
                        .offset(y: titleVisible ? 0 : 18)

                    Text(L("branding.tagline"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .opacity(taglineVisible ? 1 : 0)
                        .offset(y: taglineVisible ? 0 : 12)

                    Text(L("branding.motto"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .opacity(mottoVisible ? 1 : 0)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
        .opacity(exitSplash ? 0 : 1)
        .scaleEffect(exitSplash ? 1.04 : 1)
        .ignoresSafeArea()
        .onAppear(perform: runAnimationSequence)
    }

    private var background: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            RadialGradient(
                colors: [
                    Theme.accent.opacity(colorScheme == .dark ? 0.22 : 0.16),
                    Theme.accent.opacity(colorScheme == .dark ? 0.06 : 0.04),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
            LinearGradient(
                colors: [
                    Theme.accent.opacity(colorScheme == .dark ? 0.05 : 0.03),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func ringSize(_ index: Int) -> CGFloat {
        switch index {
        case 0: return 150
        case 1: return 190
        default: return 230
        }
    }

    private func runAnimationSequence() {
        ringPulse = true

        withAnimation(.spring(response: 0.7, dampingFraction: 0.62)) {
            iconVisible = true
        }

        withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.35)) {
            titleVisible = true
        }

        withAnimation(.spring(response: 0.65, dampingFraction: 0.85).delay(0.65)) {
            taglineVisible = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.95)) {
            mottoVisible = true
        }

        Task {
            try? await Task.sleep(for: .seconds(2.6))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.45)) {
                    exitSplash = true
                }
            }
            try? await Task.sleep(for: .seconds(0.45))
            await MainActor.run {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
