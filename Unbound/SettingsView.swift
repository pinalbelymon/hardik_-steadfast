import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(PremiumStore.self) private var premium
    @Environment(LanguageStore.self) private var languageStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    @State private var showRelapse = false
    @State private var showReset = false
    @State private var showDelete = false
    @State private var showPaywall = false
    @State private var showEditProfile = false
    @State private var showMailUnavailable = false
    @State private var showReviewUnavailable = false
    @State private var appeared = false

    var body: some View {
        @Bindable var store = store

        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                subscriptionCard
                bioCard
                notificationsCard(store: store)
                languageCard
                ratingCard
                legalCard
                supportCard
                accountActionsCard
                footerNote
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(settingsBackground)
        .navigationTitle(L("settings.title"))
        .sheet(isPresented: $showRelapse) { RelapseView() }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(store: store)
        }
        .premiumPaywall(isPresented: $showPaywall)
        .confirmationDialog(L("settings.reset.title"), isPresented: $showReset, titleVisibility: .visible) {
            Button(L("settings.reset.confirm"), role: .destructive) { store.resetProgress() }
            Button(L("common.cancel"), role: .cancel) {}
        } message: {
            Text(L("settings.reset.message"))
        }
        .confirmationDialog(L("settings.delete.title"), isPresented: $showDelete, titleVisibility: .visible) {
            Button(L("settings.delete.confirm"), role: .destructive) { store.deleteAccount() }
            Button(L("common.cancel"), role: .cancel) {}
        } message: {
            Text(L("settings.delete.message"))
        }
        .alert(L("settings.review_unavailable.title"), isPresented: $showReviewUnavailable) {
            Button(L("common.ok"), role: .cancel) {}
        } message: {
            Text(L("settings.review_unavailable.message"))
        }
        .alert(L("settings.mail_unavailable.title"), isPresented: $showMailUnavailable) {
            Button(L("common.ok"), role: .cancel) {}
        } message: {
            Text(L("settings.mail_unavailable.message", SupportMail.address))
        }
        .alert(L("settings.restore.title"), isPresented: restoreAlertBinding) {
            Button(L("common.ok"), role: .cancel) {}
        } message: {
            if let message = premium.purchaseMessage {
                Text(message)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 72, height: 72)
                Image(store.treeStage.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("settings.journey.title"))
                    .font(.title3.bold())
                Text(L("settings.journey.streak", store.currentStreak, store.treeStage.title))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(L("settings.journey.started", store.startDate.formatted(date: .abbreviated, time: .omitted)))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(18)
        .continuousCard(
            border: Theme.accent.opacity(colorScheme == .dark ? 0.25 : 0.18),
            borderWidth: 1
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: - Subscription

    private var subscriptionCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    Image(systemName: premium.isPremium ? "checkmark.seal.fill" : "crown.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(premium.isPremium ? L("settings.premium.active") : L("settings.premium.upgrade"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if premium.isPremium {
                        Text(L("settings.premium.plan_detail", premium.activePlanTitle, premium.activePlanDetail ?? L("settings.premium.subscribed")))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(L("settings.premium.change_plan"))
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                    } else {
                        Text(L("settings.premium.unlock"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .padding(16)
            .continuousCard(
                border: Theme.accent.opacity(premium.isPremium ? 0.45 : 0.25),
                borderWidth: premium.isPremium ? 1.5 : 1
            )
        }
        .buttonStyle(PressableButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05), value: appeared)
    }

    // MARK: - Bio

    private var bioCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L("settings.profile.title"))
                    .font(.headline)
                Spacer()
                Button(L("common.edit")) { showEditProfile = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }

            bioRow(icon: store.ageGroup?.icon ?? "person.fill", title: L("settings.profile.age"), value: store.ageGroup?.title ?? L("common.not_set"))
            bioDivider
            bioRow(icon: store.goal?.icon ?? "target", title: L("settings.profile.goal"), value: store.goal?.title ?? L("common.not_set"))
            bioDivider
            bioRow(icon: store.motivation?.icon ?? "heart.fill", title: L("settings.profile.motivation"), value: store.motivation?.title ?? L("common.not_set"))

            Button {
                showRelapse = true
            } label: {
                Label(L("settings.profile.log_relapse"), systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .continuousCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.1), value: appeared)
    }

    private var bioDivider: some View {
        Rectangle()
            .fill(Color(uiColor: .separator).opacity(0.35))
            .frame(height: 1)
    }

    private func bioRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 34, height: 34)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
        }
    }

    // MARK: - Notifications

    private func notificationsCard(store: AppStore) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("settings.notifications.title"))
                .font(.headline)

            Toggle(isOn: Binding(
                get: { store.reminderEnabled },
                set: { enabled in store.setReminder(enabled: enabled) }
            )) {
                Label(L("settings.notifications.daily_reminder"), systemImage: "bell.fill")
                    .font(.subheadline.weight(.medium))
            }
            .tint(Theme.accent)

            if store.reminderEnabled {
                DatePicker(
                    L("settings.notifications.reminder_time"),
                    selection: Binding(
                        get: { store.reminderTime },
                        set: { store.setReminder(enabled: true, time: $0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .font(.subheadline)
            }
        }
        .padding(16)
        .continuousCard()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.reminderEnabled)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 18)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.15), value: appeared)
    }

    // MARK: - Language

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L("settings.language.title"))
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

            NavigationLink {
                LanguagePickerView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "globe")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("settings.language.current"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(languageStore.current.nativeDisplayName)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
        }
        .continuousCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 18)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.16), value: appeared)
    }

    // MARK: - Rating & Review

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("settings.rating.title"))
                            .font(.headline)
                        Text(L("settings.rating.message", L("branding.name")))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.yellow.opacity(0.25),
                                        Theme.accent.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundStyle(.yellow)
                    }
                }

                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow.opacity(0.85))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color(uiColor: .separator).opacity(0.35))
                .frame(height: 1)
                .padding(.leading, 56)

            settingsActionRow(title: L("settings.rating.rate"), icon: "hand.thumbsup.fill") {
                requestReview()
            }
            Rectangle()
                .fill(Color(uiColor: .separator).opacity(0.35))
                .frame(height: 1)
                .padding(.leading, 56)
            settingsActionRow(title: L("settings.rating.write_review"), icon: "square.and.pencil") {
                openWriteReview()
            }
        }
        .continuousCard(
            border: Color.yellow.opacity(colorScheme == .dark ? 0.22 : 0.18),
            borderWidth: 1
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 18)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.17), value: appeared)
    }

    // MARK: - Legal & Support

    private var legalCard: some View {
        settingsLinksCard(title: L("settings.legal.title"), items: [
            (L("settings.legal.privacy"), "hand.raised", LegalLinks.privacyPolicy),
            (L("settings.legal.terms"), "doc.text", LegalLinks.termsOfUse),
            (L("settings.legal.eula"), "apple.logo", LegalLinks.appleEULA)
        ])
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L("settings.support.title"))
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

            settingsActionRow(title: L("settings.support.restore"), icon: "arrow.clockwise") {
                Task { await premium.restorePurchases() }
            }
            Rectangle()
                .fill(Color(uiColor: .separator).opacity(0.35))
                .frame(height: 1)
                .padding(.leading, 56)
            settingsActionRow(title: L("settings.support.contact"), icon: "envelope") {
                openSupportEmail()
            }
        }
        .continuousCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.2), value: appeared)
    }

    private func settingsLinksCard(title: String, items: [(String, String, URL)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(Color(uiColor: .separator).opacity(0.35))
                        .frame(height: 1)
                        .padding(.leading, 56)
                }
                Link(destination: item.2) {
                    HStack(spacing: 14) {
                        Image(systemName: item.1)
                            .font(.subheadline)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 28)
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
            }
        }
        .continuousCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 22)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.18), value: appeared)
    }

    private func settingsActionRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Account Actions

    private var accountActionsCard: some View {
        VStack(spacing: 0) {
            settingsActionRow(title: L("settings.account.reset"), icon: "arrow.counterclockwise.circle") {
                showReset = true
            }
            Rectangle()
                .fill(Color(uiColor: .separator).opacity(0.35))
                .frame(height: 1)
                .padding(.leading, 56)
            Button {
                showDelete = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .frame(width: 28)
                    Text(L("settings.account.delete"))
                        .font(.subheadline)
                    Spacer()
                }
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
        }
        .continuousCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.25), value: appeared)
    }

    private var footerNote: some View {
        Text(L("settings.footer"))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    private var settingsBackground: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            RadialGradient(
                colors: [
                    Theme.accent.opacity(colorScheme == .dark ? 0.10 : 0.06),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }

    private var restoreAlertBinding: Binding<Bool> {
        Binding(
            get: { premium.purchaseMessage != nil && !premium.isPurchasing },
            set: { if !$0 { premium.purchaseMessage = nil } }
        )
    }

    private func openSupportEmail() {
        guard let url = SupportMail.contactURL(
            currentStreak: store.currentStreak,
            bestStreak: store.bestStreak
        ) else {
            showMailUnavailable = true
            return
        }

        openURL(url) { accepted in
            if !accepted {
                showMailUnavailable = true
            }
        }
    }

    private func openWriteReview() {
        guard let url = AppBranding.writeReviewURL else {
            requestReview()
            return
        }

        openURL(url) { accepted in
            if !accepted {
                showReviewUnavailable = true
            }
        }
    }
}
