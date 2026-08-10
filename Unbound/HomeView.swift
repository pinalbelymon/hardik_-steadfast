import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(ExerciseStore.self) private var exerciseStore
    @Environment(ScreenTimeStore.self) private var screenTime
    @Environment(PremiumStore.self) private var premium
    @Environment(\.colorScheme) private var colorScheme

    @State private var showCheckIn = false
    @State private var showExercise = false
    @State private var showCraving = false
    @State private var showRelapse = false
    @State private var showPaywall = false
    @State private var navigateToScreenTime = false
    @State private var rescuePulse = false

    private var dailyExercise: Exercise {
        exerciseStore.dailyExercise(appStore: store)
    }

    private var goalsCompleted: Int {
        [store.hasCheckedInToday, exerciseStore.doneToday].filter { $0 }.count
    }

    private var allGoalsDone: Bool { goalsCompleted == 2 }

    private var stageProgress: Double {
        guard let nextDay = store.treeStage.nextDay else { return 1 }
        let previousDay: Int = {
            switch store.treeStage {
            case .seed: return 0
            case .sprout: return 3
            case .smallPlant: return 7
            case .youngTree: return 14
            case .bigTree: return 30
            case .floweringTree: return 60
            case .strongTree: return 90
            }
        }()
        let span = max(nextDay - previousDay, 1)
        let progress = Double(store.currentStreak - previousDay) / Double(span)
        return min(max(progress, 0), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                homeHeader
                    .stagger(0)
                streakCard
                    .stagger(1)
                lifeTreeCard
                    .stagger(2)
                todaySection
                    .stagger(3)
                rescueButton
                    .stagger(4)
                screenTimeCard
                    .stagger(5)
                progressSummary
                    .stagger(6)
                Button {
                    showRelapse = true
                } label: {
                    Text(L("home.relapse.link"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
                .stagger(7)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(homeBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCheckIn) { CheckInView() }
        .sheet(isPresented: $showExercise) {
            ExerciseDetailView(exercise: dailyExercise)
        }
        .sheet(isPresented: $showCraving) { CravingHelpView() }
        .sheet(isPresented: $showRelapse) { RelapseView() }
        .premiumPaywall(isPresented: $showPaywall)
        .navigationDestination(isPresented: $navigateToScreenTime) { ScreenTimeView() }
        .onAppear {
            screenTime.refreshFromSharedDefaults()
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                rescuePulse = true
            }
            presentQuestExpiredPaywallIfNeeded()
        }
    }

    private static let questExpiredPaywallKey = "steadfast.questExpiredPaywallShown"

    private func presentQuestExpiredPaywallIfNeeded() {
        guard !premium.canAccessTodaysQuest, !premium.isPremium else { return }
        guard !UserDefaults.standard.bool(forKey: Self.questExpiredPaywallKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.questExpiredPaywallKey)
        showPaywall = true
    }

    // MARK: - Background

    private var homeBackground: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            RadialGradient(
                colors: [
                    Theme.accent.opacity(colorScheme == .dark ? 0.14 : 0.10),
                    .clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var homeHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.greeting)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 6) {
                stageBadge
                goalsBadge
            }
        }
        .padding(.top, 4)
    }

    private var stageBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "leaf.fill")
                .font(.caption2)
            Text(store.treeStage.title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.accent.opacity(colorScheme == .dark ? 0.18 : 0.12), in: Capsule())
    }

    private var goalsBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: allGoalsDone ? "star.fill" : "target")
                .font(.caption2)
            Text("\(goalsCompleted)/2")
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .foregroundStyle(allGoalsDone ? Theme.accent : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            allGoalsDone
                ? Theme.accent.opacity(colorScheme == .dark ? 0.18 : 0.12)
                : Color(uiColor: .tertiarySystemFill),
            in: Capsule()
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: allGoalsDone)
    }

    // MARK: - Streak

    private var streakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 64, height: 64)
                Text(store.currentStreak == 0 ? "🌱" : "🔥")
                    .font(.system(size: 36))
                    .symbolEffect(.bounce, value: store.currentStreak)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(store.currentStreak)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text(store.currentStreak == 1 ? L("common.day") : L("common.days"))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.88))
                }
                Text(store.encouragement)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Theme.accent,
                    Theme.accent.opacity(colorScheme == .dark ? 0.72 : 0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
                .padding(14)
        }
        .foregroundStyle(.white)
        .shadow(color: Theme.accent.opacity(colorScheme == .dark ? 0.35 : 0.25), radius: 16, y: 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.currentStreak)
    }

    // MARK: - Life Tree

    private var lifeTreeCard: some View {
        VStack(spacing: 14) {
            ZStack {
                if allGoalsDone {
                    ForEach(0..<6, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.caption2)
                            .foregroundStyle(Theme.accent.opacity(0.7))
                            .offset(sparkleOffset(index))
                            .animation(
                                .easeInOut(duration: 2.2)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.25),
                                value: allGoalsDone
                            )
                    }
                }

                LifeTreeView(stage: store.treeStage)
                    .frame(height: 190)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                HStack {
                    Text(store.treeStage.title)
                        .font(.headline)
                    Spacer()
                    if store.treeStage.nextDay != nil {
                        Text("\(Int(stageProgress * 100))%")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    }
                }

                if store.treeStage.nextDay != nil {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(uiColor: .tertiarySystemFill))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.treeCanopy],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * stageProgress)
                        }
                    }
                    .frame(height: 8)
                }

                Text(nextStageText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .continuousCard(
            border: allGoalsDone
                ? Theme.accent.opacity(colorScheme == .dark ? 0.35 : 0.28)
                : Color(uiColor: .separator).opacity(colorScheme == .dark ? 0.35 : 0.25),
            borderWidth: allGoalsDone ? 1.5 : 0.5
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.treeStage)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: stageProgress)
    }

    private func sparkleOffset(_ index: Int) -> CGSize {
        let angles: [CGSize] = [
            CGSize(width: -90, height: -60),
            CGSize(width: 95, height: -50),
            CGSize(width: -70, height: 40),
            CGSize(width: 80, height: 55),
            CGSize(width: 0, height: -75),
            CGSize(width: 0, height: 70)
        ]
        return angles[index % angles.count]
    }

    private var nextStageText: String {
        guard let nextDay = store.treeStage.nextDay else {
            return L("home.tree.strongest")
        }
        if store.currentStreak == 0 {
            return L("home.tree.plant_seed")
        }
        let daysLeft = max(nextDay - store.currentStreak, 0)
        if daysLeft <= 0 { return L("home.tree.almost_there") }
        let stageTitle = TreeStage.stage(forDay: nextDay).title
        let dayWord = daysLeft == 1 ? L("common.day") : L("common.days")
        return L("home.tree.days_to_stage", daysLeft, dayWord, stageTitle)
    }

    // MARK: - Today's Goals

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L("home.quest.title"))
                    .font(.title3.bold())
                Spacer()
                if !premium.canAccessTodaysQuest {
                    Label(L("common.premium"), systemImage: "lock.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                Text(L("home.quest.progress", goalsCompleted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(allGoalsDone ? Theme.accent : .secondary)
            }

            if !premium.canAccessTodaysQuest {
                Text(L("home.quest.expired_message"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            goalRow(
                icon: store.hasCheckedInToday ? "checkmark.circle.fill" : "face.smiling",
                title: L("home.quest.check_in.title"),
                subtitle: L("home.quest.check_in.subtitle"),
                done: store.hasCheckedInToday,
                locked: !premium.canAccessTodaysQuest && !store.hasCheckedInToday
            ) {
                PremiumGate.openQuest(showPaywall: $showPaywall, premium: premium) {
                    showCheckIn = true
                }
            }
            goalRow(
                icon: exerciseStore.doneToday ? "checkmark.circle.fill" : dailyExercise.category.icon,
                title: exerciseStore.doneToday ? L("home.quest.exercise.done_title") : L("home.quest.exercise.title"),
                subtitle: L("home.quest.exercise.subtitle", dailyExercise.localizedTitle, dailyExercise.minutes),
                done: exerciseStore.doneToday,
                locked: !premium.canAccessTodaysQuest && !exerciseStore.doneToday
            ) {
                PremiumGate.openQuest(showPaywall: $showPaywall, premium: premium) {
                    showExercise = true
                }
            }
        }
        .padding(20)
        .continuousCard()
    }

    private func goalRow(icon: String, title: String, subtitle: String, done: Bool, locked: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(done ? Theme.accent : Color(uiColor: .secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(
                        done ? Theme.accent.opacity(colorScheme == .dark ? 0.2 : 0.14) : Color(uiColor: .tertiarySystemFill),
                        in: Circle()
                    )
                    .symbolEffect(.bounce, value: done)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(done ? .secondary : .primary)
                        .strikethrough(done, color: .secondary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : (done ? "checkmark" : "chevron.right"))
                    .font(.footnote.bold())
                    .foregroundStyle(locked ? Theme.accent : (done ? Theme.accent : Color(uiColor: .tertiaryLabel)))
            }
            .padding(12)
            .background(
                done
                    ? Theme.accent.opacity(colorScheme == .dark ? 0.08 : 0.06)
                    : Color(uiColor: .tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Rescue

    private var rescueButton: some View {
        Button {
            PremiumGate.openTools(showPaywall: $showPaywall, premium: premium) {
                showCraving = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(rescueGradient.opacity(rescuePulse ? 0.5 : 0.15), lineWidth: 3)
                        .frame(width: 52, height: 52)
                        .scaleEffect(rescuePulse ? 1.08 : 1)
                    Circle()
                        .fill(rescueGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: "hand.raised.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(L("home.rescue.title"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(L("home.rescue.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(rescueGradient)
            }
            .padding(16)
            .continuousCard(
                border: Color.adaptive(
                    light: UIColor(red: 0.95, green: 0.45, blue: 0.20, alpha: 0.35),
                    dark: UIColor(red: 1.0, green: 0.55, blue: 0.28, alpha: 0.4)
                ),
                borderWidth: 1
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var rescueGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.adaptive(
                    light: UIColor(red: 0.95, green: 0.45, blue: 0.20, alpha: 1),
                    dark: UIColor(red: 1.0, green: 0.55, blue: 0.28, alpha: 1)
                ),
                Color.adaptive(
                    light: UIColor(red: 0.88, green: 0.28, blue: 0.32, alpha: 1),
                    dark: UIColor(red: 0.95, green: 0.38, blue: 0.42, alpha: 1)
                )
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Screen Time

    private var screenTimeCard: some View {
        Button {
            PremiumGate.openTools(showPaywall: $showPaywall, premium: premium) {
                navigateToScreenTime = true
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    ProgressRingView(progress: screenTime.goalProgress, lineWidth: 7, size: 58)
                    Image(systemName: premium.canAccessTools ? "hourglass" : "lock.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(premium.canAccessTools
                            ? (screenTime.isOverLimit ? .orange : Theme.accent)
                            : Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(L("home.screen_time.title"))
                            .font(.headline)
                        if premium.canAccessTools, screenTime.isOverLimit {
                            Text(L("home.screen_time.over_goal"))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.orange, in: Capsule())
                        } else if !premium.canAccessTools {
                            Text(L("common.premium"))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Theme.accent, in: Capsule())
                        }
                    }
                    Text(premium.canAccessTools
                        ? L("home.screen_time.used_today", screenTime.formattedSeconds(screenTime.todayTotalSeconds))
                        : L("home.screen_time.unlock_tracking"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                    Text(premium.canAccessTools ? L("home.screen_time.tap_view") : L("home.screen_time.tap_upgrade"))
                        .font(.caption2)
                        .foregroundStyle(Theme.accent)
                }

                Spacer()

                Image(systemName: premium.canAccessTools ? "chevron.right" : "lock.fill")
                    .font(.footnote.bold())
                    .foregroundStyle(premium.canAccessTools ? Color(uiColor: .tertiaryLabel) : Theme.accent)
            }
            .padding(18)
            .continuousCard(
                border: screenTime.isOverLimit && premium.canAccessTools
                    ? Color.orange.opacity(colorScheme == .dark ? 0.4 : 0.3)
                    : Theme.accent.opacity(colorScheme == .dark ? 0.2 : 0.15),
                borderWidth: 1
            )
        }
        .buttonStyle(PressableButtonStyle())
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: screenTime.todayTotalSeconds)
    }

    // MARK: - Stats

    private var progressSummary: some View {
        HStack(spacing: 0) {
            summaryItem(value: store.currentStreak, label: L("home.stats.days_clean"), icon: "flame.fill")
            divider
            summaryItem(value: store.bestStreak, label: L("home.stats.best_streak"), icon: "trophy.fill")
            divider
            summaryItem(value: store.totalSuccessfulDays, label: L("home.stats.total_days"), icon: "calendar")
        }
        .padding(.vertical, 14)
        .continuousCard()
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(uiColor: .separator).opacity(0.35))
            .frame(width: 1, height: 36)
    }

    private func summaryItem(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Theme.accent.opacity(0.85))
            Text("\(value)")
                .font(.title3.bold().monospacedDigit())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
