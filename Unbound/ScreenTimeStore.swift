import Foundation
import Observation
import FamilyControls
import UserNotifications

@Observable
final class ScreenTimeStore {
    private static let key = "unbound.screentime.meta.v2"

    var dailyLimitMinutes: Int
    var alertsEnabled: Bool
    var appLimitSelection: FamilyActivitySelection
    var appLimitMinutes: Int

    /// Real usage mirrored from the Device Activity Report extension via App Group.
    var todayTotalSeconds: TimeInterval
    var yesterdayTotalSeconds: TimeInterval

    private var last80AlertDate: Date?
    private var last20AlertDate: Date?

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(PersistedScreenTime.self, from: data) {
            dailyLimitMinutes = decoded.dailyLimitMinutes
            alertsEnabled = decoded.alertsEnabled
            appLimitMinutes = decoded.appLimitMinutes
            last80AlertDate = decoded.last80AlertDate
            last20AlertDate = decoded.last20AlertDate
        } else {
            dailyLimitMinutes = 150
            alertsEnabled = false
            appLimitMinutes = 30
            last80AlertDate = nil
            last20AlertDate = nil
        }

        appLimitSelection = SharedSelectionStore.appLimitSelection
        todayTotalSeconds = SharedSelectionStore.todayTotalSeconds
        yesterdayTotalSeconds = SharedSelectionStore.yesterdayTotalSeconds

        SharedSelectionStore.dailyLimitMinutes = dailyLimitMinutes
        SharedSelectionStore.alertsEnabled = alertsEnabled
        SharedSelectionStore.appLimitMinutes = appLimitMinutes
    }

    var todayTotalMinutes: Int { Int(todayTotalSeconds / 60) }

    var isOverLimit: Bool { todayTotalMinutes >= dailyLimitMinutes }

    var remainingMinutes: Int { max(dailyLimitMinutes - todayTotalMinutes, 0) }

    var goalProgress: Double {
        guard dailyLimitMinutes > 0 else { return 0 }
        return min(Double(todayTotalMinutes) / Double(dailyLimitMinutes), 1)
    }

    var comparisonMinutes: Int {
        Int((todayTotalSeconds - yesterdayTotalSeconds) / 60)
    }

    var hasAppLimits: Bool {
        !appLimitSelection.applicationTokens.isEmpty
            || !appLimitSelection.categoryTokens.isEmpty
            || !appLimitSelection.webDomainTokens.isEmpty
    }

    func formattedMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        return "\(m)m"
    }

    func formattedSeconds(_ seconds: TimeInterval) -> String {
        formattedMinutes(Int(seconds / 60))
    }

    var comparisonSeconds: TimeInterval {
        todayTotalSeconds - yesterdayTotalSeconds
    }

    var isLessThanYesterday: Bool {
        comparisonSeconds <= 0
    }

    var hasUsageToday: Bool {
        todayTotalSeconds > 0
    }

    func formattedDuration(_ seconds: TimeInterval) -> String {
        formattedSeconds(seconds)
    }

    func refreshFromSharedDefaults() {
        todayTotalSeconds = SharedSelectionStore.todayTotalSeconds
        yesterdayTotalSeconds = SharedSelectionStore.yesterdayTotalSeconds
        checkAlertThresholds()
    }

    func setDailyLimit(_ minutes: Int) {
        dailyLimitMinutes = minutes
        SharedSelectionStore.dailyLimitMinutes = minutes
        try? ScreenTimeKitManager.shared.startDailyGoalMonitoring(limitMinutes: minutes)
        save()
    }

    func setAppLimit(selection: FamilyActivitySelection, minutes: Int) {
        appLimitSelection = selection
        appLimitMinutes = minutes
        SharedSelectionStore.appLimitSelection = selection
        SharedSelectionStore.appLimitMinutes = minutes
        try? ScreenTimeKitManager.shared.startAppLimitMonitoring(selection: selection, minutes: minutes)
        save()
    }

    func clearAppLimits() {
        appLimitSelection = FamilyActivitySelection()
        SharedSelectionStore.appLimitSelection = appLimitSelection
        ScreenTimeKitManager.shared.stopAppLimitMonitoring()
        save()
    }

    func setAlerts(_ enabled: Bool) {
        alertsEnabled = enabled
        SharedSelectionStore.alertsEnabled = enabled
        if enabled {
            Task {
                await NotificationManager.requestPermission()
                checkAlertThresholds()
            }
        }
        save()
    }

    func bootstrapMonitoring() {
        try? ScreenTimeKitManager.shared.startDailyGoalMonitoring(limitMinutes: dailyLimitMinutes)
        if hasAppLimits {
            try? ScreenTimeKitManager.shared.startAppLimitMonitoring(
                selection: appLimitSelection,
                minutes: appLimitMinutes
            )
        }
    }

    func checkAlertThresholds() {
        guard alertsEnabled, todayTotalMinutes > 0 else { return }
        let today = Date().startOfDay

        let eightyPercent = Int(Double(dailyLimitMinutes) * 0.8)
        if todayTotalMinutes >= eightyPercent, !(last80AlertDate?.isSameDay(as: today) ?? false) {
            last80AlertDate = Date()
            deliverAlert(title: L("screentime.alert_title"), body: L("screentime.alert_80"))
        }

        let remaining = remainingMinutes
        if remaining > 0, remaining <= 20, !(last20AlertDate?.isSameDay(as: today) ?? false) {
            last20AlertDate = Date()
            deliverAlert(title: L("screentime.alert_title"), body: L("screentime.alert_remaining", formattedMinutes(remaining)))
        }

        save()
    }

    private func deliverAlert(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func save() {
        let state = PersistedScreenTime(
            dailyLimitMinutes: dailyLimitMinutes,
            alertsEnabled: alertsEnabled,
            appLimitMinutes: appLimitMinutes,
            last80AlertDate: last80AlertDate,
            last20AlertDate: last20AlertDate
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

private struct PersistedScreenTime: Codable {
    var dailyLimitMinutes: Int
    var alertsEnabled: Bool
    var appLimitMinutes: Int
    var last80AlertDate: Date?
    var last20AlertDate: Date?
}
