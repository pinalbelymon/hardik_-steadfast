import StoreKit
import SwiftUI

struct PostOnboardingIntroView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.requestReview) private var requestReview
    @Environment(\.colorScheme) private var colorScheme

    @State private var videoFinished = false
    @State private var showWelcomeButton = true
    @State private var rateTapped = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TreeGrowthVideoPlayer {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                    videoFinished = true
                }
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, .black.opacity(colorScheme == .dark ? 0.75 : 0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack {
                Spacer()
                if videoFinished {
                    bottomButton
                        .padding(.horizontal, 28)
                        .padding(.bottom, 52)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: videoFinished)
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: showWelcomeButton)
    }

    private var bottomButton: some View {
        Button {
//            if showWelcomeButton {
                store.completeIntro()
//            } else {
//                handleRateUs()
//            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showWelcomeButton ? "leaf.fill" : "star.fill")
                Text(showWelcomeButton ? L("intro.welcome") : L("intro.rate_us"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(buttonBackground, in: Capsule())
            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(rateTapped && !showWelcomeButton)
        .opacity(rateTapped && !showWelcomeButton ? 0.7 : 1)
    }

    private var buttonBackground: some ShapeStyle {
        if showWelcomeButton {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Theme.accent, Theme.accent.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color.adaptive(
                        light: UIColor(red: 0.98, green: 0.72, blue: 0.18, alpha: 1),
                        dark: UIColor(red: 1.0, green: 0.78, blue: 0.28, alpha: 1)
                    ),
                    Color.adaptive(
                        light: UIColor(red: 0.95, green: 0.55, blue: 0.12, alpha: 1),
                        dark: UIColor(red: 1.0, green: 0.62, blue: 0.18, alpha: 1)
                    )
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private func handleRateUs() {
        guard !rateTapped else { return }
        rateTapped = true
        requestReview()

        Task {
            try? await Task.sleep(for: .seconds(2.5))
            await MainActor.run {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                    showWelcomeButton = true
                }
            }
        }
    }
}
