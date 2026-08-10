import SwiftUI

struct ToolsView: View {
    @Environment(PremiumStore.self) private var premium

    @State private var showCraving = false
    @State private var showPaywall = false
    @State private var navigateToBlocking = false
    @State private var navigateToScreenTime = false
    @State private var navigateToExercises = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                premiumBanner

                Text(L("tools.section_header"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                toolButton(
                    icon: "shield.lefthalf.filled",
                    title: L("tools.app_blocking.title"),
                    subtitle: L("tools.app_blocking.subtitle"),
                    color: Theme.accent,
                    stagger: 0
                ) {
                    PremiumGate.openTools(showPaywall: $showPaywall, premium: premium) {
                        navigateToBlocking = true
                    }
                }

                toolButton(
                    icon: "hourglass",
                    title: L("home.screen_time.title"),
                    subtitle: L("tools.screen_time.subtitle"),
                    color: .blue,
                    stagger: 1
                ) {
                    PremiumGate.openTools(showPaywall: $showPaywall, premium: premium) {
                        navigateToScreenTime = true
                    }
                }

                toolButton(
                    icon: "figure.mind.and.body",
                    title: L("tools.exercises.title"),
                    subtitle: L("tools.exercises.subtitle"),
                    color: .purple,
                    stagger: 2
                ) {
                    PremiumGate.openTools(showPaywall: $showPaywall, premium: premium) {
                        navigateToExercises = true
                    }
                }

                toolButton(
                    icon: "hand.raised.fill",
                    title: L("tools.craving_rescue.title"),
                    subtitle: L("tools.craving_rescue.subtitle"),
                    color: .orange,
                    stagger: 3
                ) {
                    PremiumGate.openTools(showPaywall: $showPaywall, premium: premium) {
                        showCraving = true
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L("tools.title"))
        .navigationDestination(isPresented: $navigateToBlocking) { AppBlockingView() }
        .navigationDestination(isPresented: $navigateToScreenTime) { ScreenTimeView() }
        .navigationDestination(isPresented: $navigateToExercises) { ExercisesView() }
        .sheet(isPresented: $showCraving) { CravingHelpView() }
        .premiumPaywall(isPresented: $showPaywall)
        .onAppear {
            if !premium.canAccessTools {
                showPaywall = true
            }
        }
    }

    @ViewBuilder
    private var premiumBanner: some View {
        if !premium.canAccessTools {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("tools.premium_required"))
                        .font(.subheadline.weight(.semibold))
                    Text(L("tools.premium_subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(L("common.upgrade")) { showPaywall = true }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(14)
            .continuousCard(
                border: Theme.accent.opacity(0.3),
                borderWidth: 1
            )
        }
    }

    private func toolButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        stagger index: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            toolCard(icon: icon, title: title, subtitle: subtitle, color: color, locked: !premium.canAccessTools)
        }
        .buttonStyle(PressableButtonStyle())
        .stagger(index)
    }

    private func toolCard(icon: String, title: String, subtitle: String, color: Color, locked: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(locked ? Theme.accent : Color(uiColor: .tertiaryLabel))
        }
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
}
