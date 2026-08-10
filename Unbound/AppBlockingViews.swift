import SwiftUI
import FamilyControls
import ManagedSettings

struct AppBlockingView: View {
    @Environment(BlockingStore.self) private var blocking
    @State private var showQuickBlock = false
    @State private var showAuthorization = false
    @State private var showAppPicker = false
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var nativeAuthorized = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                statusCard
                blockedAppsSection
                websitesSection
                scheduleCard
                PrimaryButton(title: L("blocking.quick_block"), systemImage: "bolt.fill") {
                    if !nativeAuthorized {
                        showAuthorization = true
                    } else if !blocking.hasSelection {
                        showAppPicker = true
                    } else {
                        showQuickBlock = true
                    }
                }
                nativeStatusRow
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L("blocking.title"))
        .hidesTabBar()
        .onAppear {
            ScreenTimeKitManager.shared.refreshStatus()
            nativeAuthorized = ScreenTimeKitManager.shared.isAuthorized
            pickerSelection = blocking.activitySelection
        }
        .sheet(isPresented: $showQuickBlock) { QuickBlockView() }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $pickerSelection)
        .onChange(of: showAppPicker) { _, isPresented in
            if !isPresented {
                blocking.updateSelection(pickerSelection)
            }
        }
        .alert(L("blocking.permission_title"), isPresented: $showAuthorization) {
            Button(L("blocking.request_permission")) {
                Task {
                    await blocking.requestNativeAuthorization()
                    nativeAuthorized = ScreenTimeKitManager.shared.isAuthorized
                    if nativeAuthorized {
                        showAppPicker = true
                    }
                }
            }
            Button(L("blocking.not_now"), role: .cancel) {}
        } message: {
            Text(L("blocking.permission_message"))
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "shield.fill")
                .font(.title2)
                .foregroundStyle(blocking.activeStatus ? .white : Theme.accent)
                .frame(width: 48, height: 48)
                .background(blocking.activeStatus ? Theme.accent : Theme.accent.opacity(0.15), in: Circle())
                .symbolEffect(.bounce, value: blocking.activeStatus)
            VStack(alignment: .leading, spacing: 3) {
                Text(blocking.activeStatus ? L("blocking.active") : L("blocking.inactive"))
                    .font(.headline)
                    .contentTransition(.opacity)
                Text(L("blocking.status_description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { blocking.blockingEnabled },
                set: { enabled in
                    if enabled && !nativeAuthorized {
                        showAuthorization = true
                    } else if enabled && !blocking.hasSelection {
                        showAppPicker = true
                    } else {
                        blocking.setBlocking(enabled: enabled)
                    }
                }
            ))
            .labelsHidden()
            .tint(Theme.accent)
        }
        .glassCard()
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: blocking.activeStatus)
    }

    private var blockedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("blocking.blocked_apps")).font(.headline)
                Spacer()
                Button {
                    if nativeAuthorized {
                        pickerSelection = blocking.activitySelection
                        showAppPicker = true
                    } else {
                        showAuthorization = true
                    }
                } label: {
                    Label(L("common.add"), systemImage: "plus")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                }
            }

            if blocking.applicationTokens.isEmpty && blocking.categoryTokens.isEmpty {
                Text(L("blocking.no_apps"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(blocking.applicationTokens, id: \.self) { token in
                    tokenRow {
                        Label(token)
                            .labelStyle(.titleAndIcon)
                    } onRemove: {
                        blocking.removeApplication(token)
                    }
                }
                ForEach(blocking.categoryTokens, id: \.self) { token in
                    tokenRow {
                        Label(token)
                            .labelStyle(.titleAndIcon)
                    } onRemove: {
                        blocking.removeCategory(token)
                    }
                }
            }
        }
        .glassCard()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: blocking.selectionCount)
    }

    private var websitesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L("blocking.blocked_websites")).font(.headline)
                Spacer()
                Button {
                    if nativeAuthorized {
                        pickerSelection = blocking.activitySelection
                        showAppPicker = true
                    } else {
                        showAuthorization = true
                    }
                } label: {
                    Label(L("common.add"), systemImage: "plus")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                }
            }

            if blocking.webDomainTokens.isEmpty {
                Text(L("blocking.pick_websites"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(blocking.webDomainTokens, id: \.self) { token in
                    tokenRow {
                        Label(token)
                            .labelStyle(.titleAndIcon)
                    } onRemove: {
                        blocking.removeWebDomain(token)
                    }
                }
            }
        }
        .glassCard()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: blocking.webDomainTokens.count)
    }

    private func tokenRow<Content: View>(@ViewBuilder content: () -> Content, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            content()
                .font(.subheadline.weight(.medium))
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var scheduleCard: some View {
        NavigationLink { ScheduleView() } label: {
            HStack(spacing: 14) {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(L("blocking.schedule")).font(.headline)
                    Text(blocking.scheduleSummary).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(.tertiary)
            }
            .padding(20)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var nativeStatusRow: some View {
        Button {
            showAuthorization = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: nativeAuthorized ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(nativeAuthorized ? Theme.accent : .secondary)
                Text(nativeAuthorized
                     ? L("blocking.permission_granted")
                     : L("blocking.enable_permission"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct QuickBlockView: View {
    @Environment(BlockingStore.self) private var blocking
    @Environment(\.dismiss) private var dismiss
    @State private var activated = false
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            Group {
                if activated {
                    activatedView
                } else {
                    optionsView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: activated)
            .navigationTitle(L("blocking.quick_block"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var optionsView: some View {
        VStack(spacing: 18) {
            Image(systemName: "shield.fill")
                .font(.system(size: 46))
                .foregroundStyle(Theme.accent)
                .padding(.top, 24)
            Text(L("blocking.need_break"))
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if !blocking.hasSelection {
                Text(L("blocking.select_apps_first"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 12) {
                ForEach(QuickBlockOption.allCases) { option in
                    Button {
                        blocking.startQuickBlock(option)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { activated = true }
                    } label: {
                        HStack {
                            Text(option.title).font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(
                            Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(!blocking.hasSelection)
                    .opacity(blocking.hasSelection ? 1 : 0.5)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.scale.combined(with: .opacity))
    }

    private var activatedView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulse ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.bounce, value: activated)
            }
            .frame(height: 200)
            .onAppear { pulse = true }
            Text(L("protection.activated"))
                .font(.title2.bold())
            Text(L("blocking.apps_shielded"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            PrimaryButton(title: L("common.done"), systemImage: "checkmark") { dismiss() }
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale.combined(with: .opacity))
    }
}

struct ScheduleView: View {
    @Environment(BlockingStore.self) private var blocking
    @Environment(\.dismiss) private var dismiss

    @State private var type: BlockingScheduleType = .everyDay
    @State private var start = Date()
    @State private var end = Date()
    @State private var days: Set<Int> = []

    private let weekdays = [2, 3, 4, 5, 6]
    private let weekend = [1, 7]
    private let dayNames = [1: "S", 2: "M", 3: "T", 4: "W", 5: "T", 6: "F", 7: "S"]

    var body: some View {
        Form {
            Section(L("blocking.days_section")) {
                ForEach(BlockingScheduleType.allCases) { option in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            type = option
                            switch option {
                            case .everyDay: days = Set(1...7)
                            case .weekdays: days = Set(weekdays)
                            case .weekends: days = Set(weekend)
                            case .custom: days = Set(weekdays)
                            }
                        }
                    } label: {
                        HStack {
                            Text(option.title).foregroundStyle(.primary)
                            Spacer()
                            if type == option {
                                Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            }

            if type == .custom {
                Section(L("blocking.custom_days")) {
                    HStack {
                        ForEach(1...7, id: \.self) { day in
                            dayToggle(day)
                        }
                    }
                }
            }

            Section(L("blocking.time_section")) {
                DatePicker(L("blocking.start"), selection: $start, displayedComponents: .hourAndMinute)
                DatePicker(L("blocking.end"), selection: $end, displayedComponents: .hourAndMinute)
            }

            Section {
                Button(L("blocking.save_schedule")) {
                    blocking.updateSchedule(type: type, start: start, end: end, days: Array(days).sorted())
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
        }
        .navigationTitle(L("blocking.schedule_title"))
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
        .onAppear {
            type = blocking.scheduleType
            start = blocking.startTime
            end = blocking.endTime
            days = Set(blocking.customDays)
        }
    }

    private func dayToggle(_ day: Int) -> some View {
        let selected = days.contains(day)
        return Button {
            if selected { days.remove(day) } else { days.insert(day) }
        } label: {
            Text(dayNames[day] ?? "")
                .font(.headline)
                .foregroundStyle(selected ? .white : .secondary)
                .frame(width: 38, height: 38)
                .background(selected ? Theme.accent : Color(uiColor: .tertiarySystemFill), in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}
