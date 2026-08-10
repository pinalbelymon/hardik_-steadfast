import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(PremiumStore.self) private var premium
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var treeFloat = false
    @State private var treeGlow = false
    @State private var featuresVisible = false
    @State private var plansVisible = false

    private var features: [(String, String)] {
        [
            ("shield.lefthalf.filled", L("paywall.feature.blocking")),
            ("figure.mind.and.body", L("paywall.feature.exercises")),
            ("target", L("paywall.feature.quests")),
            ("leaf.fill", L("paywall.feature.tree"))
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    featuresSection
                    plansSection
                    ctaSection
                    legalSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(paywallBackground)
            .navigationTitle(L("paywall.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.close")) { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            treeFloat = true
            treeGlow = true
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.1)) {
                featuresVisible = true
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.85).delay(0.25)) {
                plansVisible = true
            }
            Task { await premium.loadProducts() }
        }
    }

    private var ctaTitle: String {
        if premium.isPurchasing { return L("common.processing") }
        if premium.isPremium {
            if premium.activePlan == premium.selectedPlan {
                return L("paywall.cta.current_plan")
            }
            return L("paywall.cta.switch_plan", premium.selectedPlan.title)
        }
        return L("common.continue")
    }

    private var ctaDisabled: Bool {
        premium.isPurchasing || (premium.isPremium && premium.activePlan == premium.selectedPlan)
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.accent.opacity(treeGlow ? 0.22 : 0.10),
                                Theme.accent.opacity(0.02)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(treeGlow ? 1.05 : 0.95)

                Image("Big Tree")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .shadow(color: Theme.accent.opacity(0.25), radius: 20, y: 12)
                    .scaleEffect(featuresVisible ? 1.02 : 0.98)
                    .opacity(featuresVisible ? 1 : 0)
            }
            .frame(height: 200)
            .padding(.top, 4)
            
           

            if premium.isPremium, let detail = premium.activePlanDetail {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                    Text(L("paywall.active_plan", premium.activePlanTitle, detail))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.accent.opacity(0.12), in: Capsule())
            }

            Text(premium.isPremium ? L("paywall.manage") : L("paywall.unlock"))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)

            Text(premium.isPremium
                ? L("paywall.subtitle.manage")
                : L("paywall.subtitle.new"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 10) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.0)
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 36, height: 36)
                        .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(feature.1)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
                .padding(14)
                .continuousCard(cornerRadius: 18)
                .opacity(featuresVisible ? 1 : 0)
                .offset(y: featuresVisible ? 0 : 12)
                .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(Double(index) * 0.06), value: featuresVisible)
            }
        }
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPlan.allCases) { plan in
                planCard(plan)
                    .opacity(plansVisible ? 1 : 0)
                    .offset(y: plansVisible ? 0 : 16)
                    .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(planDelay(plan)), value: plansVisible)
            }
        }
    }

    private func planDelay(_ plan: SubscriptionPlan) -> Double {
        switch plan {
        case .weekly: return 0.05
        case .monthly: return 0.12
        case .yearly: return 0.19
        }
    }

    private func planCard(_ plan: SubscriptionPlan) -> some View {
        let selected = premium.selectedPlan == plan
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                premium.selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.headline)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.accent, in: Capsule())
                        }
                    }
                    Text(plan.periodLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(premium.price(for: plan))
                    .font(.title3.bold().monospacedDigit())
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Theme.accent : Color(uiColor: .tertiaryLabel))
            }
            .padding(16)
            .continuousCard(
                cornerRadius: 20,
                border: selected ? Theme.accent.opacity(0.55) : Color(uiColor: .separator).opacity(0.3),
                borderWidth: selected ? 2 : 1
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    let succeeded = await premium.purchaseSelectedPlan()
                    if succeeded {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if premium.isPurchasing {
                        SwiftUI.ProgressView()
                            .tint(.white)
                    }
                    Text(ctaTitle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: ctaDisabled
                            ? [Color(uiColor: .tertiaryLabel), Color(uiColor: .tertiaryLabel).opacity(0.8)]
                            : [Theme.accent, Theme.accent.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: ctaDisabled ? .clear : Theme.accent.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(ctaDisabled)

            Button(L("paywall.restore")) {
                Task {
                    let restored = await premium.restorePurchases()
                    if restored {
                        dismiss()
                    }
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.accent)
            .disabled(premium.isPurchasing)

            if let message = premium.purchaseMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text(L("paywall.legal.payment"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    private var legalSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                Link(L("settings.legal.privacy"), destination: LegalLinks.privacyPolicy)
                Text("·").foregroundStyle(.tertiary)
                Link(L("settings.legal.terms"), destination: LegalLinks.termsOfUse)
            }
            .font(.caption)
            .foregroundStyle(Theme.accent)

            Link(L("settings.legal.eula"), destination: LegalLinks.appleEULA)
                .font(.caption)
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var paywallBackground: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            RadialGradient(
                colors: [
                    Theme.accent.opacity(colorScheme == .dark ? 0.12 : 0.08),
                    .clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}
