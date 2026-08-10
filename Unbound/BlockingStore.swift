import Foundation
import Observation
import FamilyControls
import ManagedSettings

enum BlockingScheduleType: String, CaseIterable, Codable, Identifiable {
    case everyDay, weekdays, weekends, custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .everyDay: return L("schedule.every_day")
        case .weekdays: return L("schedule.weekdays")
        case .weekends: return L("schedule.weekends")
        case .custom: return L("schedule.custom_days")
        }
    }
}

enum QuickBlockOption: String, CaseIterable, Identifiable {
    case thirtyMinutes
    case oneHour
    case threeHours
    case untilTomorrow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thirtyMinutes: return L("block.30_min")
        case .oneHour: return L("block.1_hour")
        case .threeHours: return L("block.3_hours")
        case .untilTomorrow: return L("block.until_tomorrow")
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .threeHours: return 3 * 60 * 60
        case .untilTomorrow:
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? Date().addingTimeInterval(86400)
            return tomorrow.timeIntervalSinceNow
        }
    }
}

@Observable
final class BlockingStore {
    private static let key = "unbound.blocking.meta.v2"

    var activitySelection: FamilyActivitySelection
    var scheduleType: BlockingScheduleType
    var startTime: Date
    var endTime: Date
    var customDays: [Int]
    var blockingEnabled: Bool
    var quickBlockEnd: Date?

    private var resetTask: Task<Void, Never>?

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(PersistedBlocking.self, from: data) {
            scheduleType = decoded.scheduleType
            startTime = decoded.startTime
            endTime = decoded.endTime
            customDays = decoded.customDays
            blockingEnabled = decoded.blockingEnabled
            quickBlockEnd = decoded.quickBlockEnd
        } else {
            scheduleType = .everyDay
            startTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
            endTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
            customDays = [2, 3, 4, 5, 6]
            blockingEnabled = false
            quickBlockEnd = nil
        }

        activitySelection = SharedSelectionStore.activitySelection
        SharedSelectionStore.blockingEnabled = blockingEnabled
        SharedSelectionStore.quickBlockEnd = quickBlockEnd
        ScreenTimeKitManager.shared.refreshStatus()

        if quickBlockActive {
            ScreenTimeKitManager.shared.applyQuickBlock(selection: activitySelection)
            let remaining = (quickBlockEnd ?? Date()).timeIntervalSinceNow
            if remaining > 0 {
                scheduleQuickBlockReset(after: remaining)
            }
        }

        if blockingEnabled {
            try? rescheduleMonitoring()
        }
    }

    var applicationTokens: [ApplicationToken] {
        Array(activitySelection.applicationTokens)
    }

    var categoryTokens: [ActivityCategoryToken] {
        Array(activitySelection.categoryTokens)
    }

    var webDomainTokens: [WebDomainToken] {
        Array(activitySelection.webDomainTokens)
    }

    var hasSelection: Bool {
        !applicationTokens.isEmpty || !categoryTokens.isEmpty || !webDomainTokens.isEmpty
    }

    var selectionCount: Int {
        applicationTokens.count + categoryTokens.count + webDomainTokens.count
    }

    var activeStatus: Bool { blockingEnabled || quickBlockActive }

    var quickBlockActive: Bool { (quickBlockEnd ?? .distantPast) > Date() }

    var scheduleSummary: String {
        let start = startTime.formatted(date: .omitted, time: .shortened)
        let end = endTime.formatted(date: .omitted, time: .shortened)
        return "\(scheduleType.title) · \(start) – \(end)"
    }

    func updateSelection(_ selection: FamilyActivitySelection) {
        activitySelection = selection
        SharedSelectionStore.activitySelection = selection
        refreshShields()
        save()
    }

    func removeApplication(_ token: ApplicationToken) {
        var selection = activitySelection
        selection.applicationTokens.remove(token)
        updateSelection(selection)
    }

    func removeCategory(_ token: ActivityCategoryToken) {
        var selection = activitySelection
        selection.categoryTokens.remove(token)
        updateSelection(selection)
    }

    func removeWebDomain(_ token: WebDomainToken) {
        var selection = activitySelection
        selection.webDomainTokens.remove(token)
        updateSelection(selection)
    }

    func setBlocking(enabled: Bool) {
        blockingEnabled = enabled
        SharedSelectionStore.blockingEnabled = enabled
        if enabled {
            try? rescheduleMonitoring()
            // Also apply immediately so blocking works before the next schedule edge.
            ScreenTimeKitManager.shared.applyImmediateShield(selection: activitySelection)
        } else {
            ScreenTimeKitManager.shared.stopScheduleMonitoring()
            if !quickBlockActive {
                ScreenTimeKitManager.shared.clearImmediateShield()
            }
        }
        save()
    }

    func updateSchedule(type: BlockingScheduleType, start: Date, end: Date, days: [Int]) {
        scheduleType = type
        startTime = start
        endTime = end
        customDays = days
        if blockingEnabled {
            try? rescheduleMonitoring()
        }
        save()
    }

    func startQuickBlock(_ option: QuickBlockOption) {
        quickBlockEnd = Date().addingTimeInterval(option.seconds)
        SharedSelectionStore.quickBlockEnd = quickBlockEnd
        ScreenTimeKitManager.shared.applyQuickBlock(selection: activitySelection)
        save()
        scheduleQuickBlockReset(after: option.seconds)
    }

    func requestNativeAuthorization() async {
        await ScreenTimeKitManager.shared.requestAuthorization()
    }

    private func rescheduleMonitoring() throws {
        try ScreenTimeKitManager.shared.startScheduleMonitoring(
            type: scheduleType,
            start: startTime,
            end: endTime,
            customDays: customDays
        )
    }

    private func refreshShields() {
        if quickBlockActive {
            ScreenTimeKitManager.shared.applyQuickBlock(selection: activitySelection)
        }
        if blockingEnabled {
            ScreenTimeKitManager.shared.applyImmediateShield(selection: activitySelection)
            try? rescheduleMonitoring()
        }
    }

    private func scheduleQuickBlockReset(after seconds: TimeInterval) {
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            quickBlockEnd = nil
            SharedSelectionStore.quickBlockEnd = nil
            ScreenTimeKitManager.shared.clearQuickBlock()
            save()
        }
    }

    private func save() {
        let state = PersistedBlocking(
            scheduleType: scheduleType,
            startTime: startTime,
            endTime: endTime,
            customDays: customDays,
            blockingEnabled: blockingEnabled,
            quickBlockEnd: quickBlockEnd
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
        SharedSelectionStore.activitySelection = activitySelection
        SharedSelectionStore.blockingEnabled = blockingEnabled
        SharedSelectionStore.quickBlockEnd = quickBlockEnd
    }
}

private struct PersistedBlocking: Codable {
    var scheduleType: BlockingScheduleType
    var startTime: Date
    var endTime: Date
    var customDays: [Int]
    var blockingEnabled: Bool
    var quickBlockEnd: Date?
}
