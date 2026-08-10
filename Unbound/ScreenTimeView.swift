import SwiftUI
import DeviceActivity
import FamilyControls

struct ScreenTimeView: View {
    @Environment(ScreenTimeStore.self) private var screenTime
    @Environment(\.colorScheme) private var colorScheme

    @State private var showLimit = false
    @State private var showAppLimit = false
    @State private var showAuthorization = false
    @State private var showAppBreakdown = false
    @State private var isRefreshing = false

    @State private var context: DeviceActivityReport.Context = .dailySummary
    @State private var filter = DeviceActivityFilter(
        segment: .daily(
            during: Calendar.current.dateInterval(of: .day, for: .now) ?? DateInterval(start: Date(), duration: 86400)
        )
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if ScreenTimeKitManager.shared.isAuthorized {
                    todaySummaryCard
                        .stagger(0)

                    goalProgressCard
                        .stagger(1)

                    appLimitsSection
                        .stagger(2)

                    topAppsSection
                        .stagger(3)
                } else {
                    permissionCard
                        .stagger(0)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L("screentime.title"))
        .hidesTabBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    refreshData()
                } label: {
                    if isRefreshing {
                        SwiftUI.ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            }
        }
        .onAppear {
            ScreenTimeKitManager.shared.refreshStatus()
            screenTime.refreshFromSharedDefaults()
            screenTime.bootstrapMonitoring()
            refreshFilter()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                screenTime.refreshFromSharedDefaults()
            }
        }
        .sheet(isPresented: $showLimit) { LimitEditorView() }
        .sheet(isPresented: $showAppLimit) { AppLimitEditorView() }
        .alert(L("screentime.permission_title"), isPresented: $showAuthorization) {
            Button(L("screentime.request_permission")) {
                Task {
                    await ScreenTimeKitManager.shared.requestAuthorization()
                    screenTime.bootstrapMonitoring()
                }
            }
            Button(L("screentime.not_now"), role: .cancel) {}
        } message: {
            Text(L("screentime.permission_message"))
        }
    }

    // MARK: - Instant summary (cached — no extension wait)

    private var todaySummaryCard: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRingView(
                    progress: screenTime.goalProgress,
                    lineWidth: 11,
                    size: 108
                )
                Image(systemName: screenTime.isOverLimit ? "exclamationmark" : "hourglass")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(screenTime.isOverLimit ? .orange : Theme.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L("report.today"))
                    .font(.headline)

                Text(screenTime.formattedDuration(screenTime.todayTotalSeconds))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if screenTime.hasUsageToday {
                    comparisonLabel
                } else {
                    Text(L("report.no_usage"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if screenTime.isOverLimit {
                    Text(L("home.screen_time.over_goal"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange, in: Capsule())
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .continuousCard(
            border: screenTime.isOverLimit
                ? Color.orange.opacity(colorScheme == .dark ? 0.35 : 0.25)
                : Theme.accent.opacity(colorScheme == .dark ? 0.2 : 0.12)
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: screenTime.todayTotalSeconds)
    }

    private var comparisonLabel: some View {
        let delta = abs(screenTime.comparisonSeconds)
        let less = screenTime.isLessThanYesterday
        return Label(
            L(less ? "report.comparison.less" : "report.comparison.more", screenTime.formattedDuration(delta)),
            systemImage: less ? "arrow.down.right" : "arrow.up.right"
        )
        .font(.caption)
        .foregroundStyle(less ? .green : .orange)
        .lineLimit(2)
    }

    private var goalProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L("screentime.daily_goal"))
                    .font(.headline)
                Spacer()
                Button(L("screentime.edit_limit")) { showLimit = true }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.accent)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(screenTime.formattedDuration(screenTime.todayTotalSeconds))
                    .font(.title3.bold())
                    .contentTransition(.numericText())
                Text(L("report.goal_of", screenTime.formattedMinutes(screenTime.dailyLimitMinutes)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(uiColor: .tertiarySystemFill))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: screenTime.isOverLimit
                                    ? [.orange, .red.opacity(0.85)]
                                    : [Theme.accent, Theme.accent.opacity(0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * screenTime.goalProgress)
                }
            }
            .frame(height: 10)

            Text(goalStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .glassCard()
    }

    private var goalStatusText: String {
        if screenTime.isOverLimit {
            return L("report.goal_reached")
        }
        let remaining = max(screenTime.remainingMinutes, 0)
        return L("report.goal_remaining", screenTime.formattedMinutes(remaining))
    }

    // MARK: - Lazy top apps (Apple report extension — slow)

    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("report.top_apps"))
                    .font(.headline)
                Spacer()
                if showAppBreakdown {
                    Button(L("common.hide")) { showAppBreakdown = false }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if showAppBreakdown {
                DeviceActivityReport(context, filter: filter)
                    .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showAppBreakdown = true
                        refreshFilter()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "apps.iphone")
                            .font(.title3)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 36, height: 36)
                            .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(L("screentime.show_breakdown"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(L("screentime.show_breakdown_hint"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .padding(14)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .glassCard()
    }

    private var permissionCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
            Text(L("screentime.real_title"))
                .font(.title3.bold())
            Text(L("screentime.grant_description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: L("screentime.enable"), systemImage: "lock.open") {
                showAuthorization = true
            }
        }
        .padding(24)
        .glassCard()
    }

    private var appLimitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("screentime.app_limits")).font(.headline)
                Spacer()
                Button { showAppLimit = true } label: {
                    Label(screenTime.hasAppLimits ? L("common.edit") : L("common.add"), systemImage: "plus")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                }
            }

            if !screenTime.hasAppLimits {
                Text(L("screentime.no_limits"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(screenTime.appLimitSelection.applicationTokens), id: \.self) { token in
                    HStack(spacing: 10) {
                        Label(token)
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(L("screentime.per_day", screenTime.formattedMinutes(screenTime.appLimitMinutes)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Button(L("screentime.clear_limits"), role: .destructive) {
                    screenTime.clearAppLimits()
                }
                .font(.subheadline)
            }
        }
        .glassCard()
    }

    private func refreshData() {
        isRefreshing = true
        refreshFilter()
        screenTime.refreshFromSharedDefaults()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isRefreshing = false
        }
    }

    private func refreshFilter() {
        let interval = Calendar.current.dateInterval(of: .day, for: .now)
            ?? DateInterval(start: Date(), duration: 86400)
        filter = DeviceActivityFilter(segment: .daily(during: interval))
        context = .dailySummary
    }
}

struct LimitEditorView: View {
    @Environment(ScreenTimeStore.self) private var screenTime
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L("screentime.daily_goal_section")) {
                    ForEach([60, 90, 120, 150, 180], id: \.self) { minutes in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                screenTime.setDailyLimit(minutes)
                            }
                        } label: {
                            HStack {
                                Text(screenTime.formattedMinutes(minutes)).foregroundStyle(.primary)
                                Spacer()
                                if screenTime.dailyLimitMinutes == minutes {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                                }
                            }
                        }
                    }
                    Stepper(
                        L("screentime.custom_format", screenTime.formattedMinutes(screenTime.dailyLimitMinutes)),
                        value: Binding(get: { screenTime.dailyLimitMinutes }, set: { screenTime.setDailyLimit($0) }),
                        in: 15...600,
                        step: 15
                    )
                }
                Section(L("screentime.alerts_section")) {
                    Toggle(L("screentime.goal_alerts"), isOn: Binding(get: { screenTime.alertsEnabled }, set: { screenTime.setAlerts($0) }))
                }
            }
            .navigationTitle(L("screentime.goal_editor_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct AppLimitEditorView: View {
    @Environment(ScreenTimeStore.self) private var screenTime
    @Environment(\.dismiss) private var dismiss
    @State private var selection = FamilyActivitySelection()
    @State private var minutes = 30
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section(L("screentime.apps_section")) {
                    Button(L("screentime.choose_apps")) {
                        selection = screenTime.appLimitSelection
                        showPicker = true
                    }
                    if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
                        Text(L("screentime.no_apps_selected"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(selection.applicationTokens), id: \.self) { token in
                            Label(token)
                        }
                        ForEach(Array(selection.categoryTokens), id: \.self) { token in
                            Label(token)
                        }
                    }
                }
                Section(L("screentime.limit_per_day")) {
                    Stepper(L("screentime.minutes_format", String(minutes)), value: $minutes, in: 5...600, step: 5)
                }
                Section {
                    Button(L("screentime.save_limit")) {
                        screenTime.setAppLimit(selection: selection, minutes: minutes)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .disabled(selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty)
                }
            }
            .navigationTitle(L("screentime.app_limit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selection = screenTime.appLimitSelection
                minutes = screenTime.appLimitMinutes
            }
            .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        }
        .presentationDetents([.medium, .large])
    }
}
