import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    @State private var page = 0
    @State private var ageGroup: AgeGroup?
    @State private var goal: Goal?
    @State private var motivation: Motivation?
    @State private var reminder: ReminderFrequency?
    @State private var pulse = false

    private var canContinue: Bool {
        switch page {
        case 1: return ageGroup != nil
        case 2: return goal != nil
        case 3: return motivation != nil
        case 4: return reminder != nil
        default: return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            indicator

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    pageContent
                        .id(page)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
            }

            Group {
                if page < 4 {
                    PrimaryButton(title: page == 0 ? L("onboarding.button.get_started") : L("onboarding.button.continue")) {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                            page += 1
                        }
                    }
                    .opacity(canContinue ? 1 : 0.5)
                    .allowsHitTesting(canContinue)
                } else {
                    VStack(spacing: 12) {
                        if reminder != nil {
                            Text(L("onboarding.ready"))
                                .font(.headline)
                                .foregroundStyle(Theme.accent)
                                .transition(.scale.combined(with: .opacity))
                        }
                        PrimaryButton(title: L("onboarding.button.start_journey"), systemImage: "leaf.fill") {
                            finish()
                        }
                        .opacity(canContinue ? 1 : 0.5)
                        .allowsHitTesting(canContinue)
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: reminder)
                }
            }
            .padding(.top, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: canContinue)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.calmGradient)
    }

    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index <= page ? Theme.accent : Theme.accent.opacity(0.2))
                    .frame(width: index == page ? 28 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case 0: welcomePage
        case 1: agePage
        case 2: goalPage
        case 3: motivationPage
        default: reminderPage
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(pulse ? 0.18 : 0.08))
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulse ? 1.05 : 0.95)
                Circle()
                    .fill(Theme.accent.opacity(pulse ? 0.12 : 0.05))
                    .frame(width: 260, height: 260)
                    .scaleEffect(pulse ? 0.95 : 1.05)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(Theme.accent)
            }
            .frame(height: 280)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            Text(L("onboarding.welcome.title"))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Text(L("onboarding.welcome.subtitle"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var agePage: some View {
        VStack(spacing: 16) {
            Text(L("onboarding.age.title"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(L("onboarding.age.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                ForEach(Array(AgeGroup.allCases.enumerated()), id: \.element.id) { index, option in
                    OptionCard(
                        title: option.title,
                        icon: option.icon,
                        isSelected: ageGroup == option,
                        action: { ageGroup = option }
                    )
                    .stagger(index)
                }
            }
            Spacer()
        }
        .padding(.top, 20)
    }

    private var goalPage: some View {
        VStack(spacing: 16) {
            Text(L("onboarding.goal.title"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                ForEach(Array(Goal.allCases.enumerated()), id: \.element.id) { index, option in
                    OptionCard(
                        title: option.title,
                        icon: option.icon,
                        isSelected: goal == option,
                        action: { goal = option }
                    )
                    .stagger(index)
                }
            }
            Spacer()
        }
        .padding(.top, 20)
    }

    private var motivationPage: some View {
        VStack(spacing: 16) {
            Text(L("onboarding.motivation.title"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                ForEach(Array(Motivation.allCases.enumerated()), id: \.element.id) { index, option in
                    OptionCard(
                        title: option.title,
                        icon: option.icon,
                        isSelected: motivation == option,
                        action: { motivation = option }
                    )
                    .stagger(index)
                }
            }
            Spacer()
        }
        .padding(.top, 20)
    }

    private var reminderPage: some View {
        VStack(spacing: 16) {
            Text(L("onboarding.reminder.title"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                ForEach(Array(ReminderFrequency.allCases.enumerated()), id: \.element.id) { index, option in
                    OptionCard(
                        title: option.title,
                        subtitle: subtitle(for: option),
                        icon: option.icon,
                        isSelected: reminder == option,
                        action: { reminder = option }
                    )
                    .stagger(index)
                }
            }
            Spacer()
        }
        .padding(.top, 20)
    }

    private func subtitle(for frequency: ReminderFrequency) -> String? {
        switch frequency {
        case .daily: return L("onboarding.reminder.daily_subtitle")
        case .fewTimesAWeek: return L("onboarding.reminder.few_times_subtitle")
        case .none: return L("onboarding.reminder.none_subtitle")
        }
    }

    private func finish() {
        guard let ageGroup, let goal, let motivation, let reminder else { return }
        if reminder != .none {
            Task {
                _ = await NotificationManager.requestPermission()
            }
        }
        store.completeOnboarding(ageGroup: ageGroup, goal: goal, motivation: motivation, reminder: reminder)
    }
}
