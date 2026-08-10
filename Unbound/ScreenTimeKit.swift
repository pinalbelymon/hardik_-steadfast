import FamilyControls
import ManagedSettings
import DeviceActivity
import Foundation

@Observable
@MainActor
final class ScreenTimeKitManager {
    static let shared = ScreenTimeKitManager()

    private let quickBlockStore = ManagedSettingsStore(named: UnboundShared.Store.quickBlock)
    private let scheduleStore = ManagedSettingsStore(named: UnboundShared.Store.schedule)
    private let center = DeviceActivityCenter()

    private(set) var status: AuthorizationStatus = .notDetermined

    var isAuthorized: Bool { status == .approved }

    private init() {
        refreshStatus()
    }

    func refreshStatus() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            // User denied or Simulator / missing capability.
        }
        refreshStatus()
    }

    func applyQuickBlock(selection: FamilyActivitySelection) {
        guard isAuthorized else { return }
        ShieldApplier.apply(selection, to: quickBlockStore)
    }

    func clearQuickBlock() {
        ShieldApplier.clear(quickBlockStore)
    }

    func applyImmediateShield(selection: FamilyActivitySelection) {
        guard isAuthorized else { return }
        ShieldApplier.apply(selection, to: scheduleStore)
    }

    func clearImmediateShield() {
        ShieldApplier.clear(scheduleStore)
    }

    func startScheduleMonitoring(
        type: BlockingScheduleType,
        start: Date,
        end: Date,
        customDays: [Int]
    ) throws {
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true,
            warningTime: nil
        )

        // DeviceActivity schedules are time-of-day windows. Day filters are enforced
        // inside the monitor via SharedSelectionStore when needed.
        _ = type
        _ = customDays

        try center.startMonitoring(UnboundShared.Activity.schedule, during: schedule)
        SharedSelectionStore.scheduleEnabled = true
    }

    func stopScheduleMonitoring() {
        center.stopMonitoring([UnboundShared.Activity.schedule])
        SharedSelectionStore.scheduleEnabled = false
        if !SharedSelectionStore.quickBlockActive {
            clearImmediateShield()
        }
    }

    func startDailyGoalMonitoring(limitMinutes: Int) throws {
        guard isAuthorized, limitMinutes > 0 else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let threshold = DateComponents(minute: limitMinutes)
        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            DeviceActivityEvent.Name("dailyGoalThreshold"): DeviceActivityEvent(threshold: threshold)
        ]

        try center.startMonitoring(UnboundShared.Activity.dailyGoal, during: schedule, events: events)
    }

    func startAppLimitMonitoring(selection: FamilyActivitySelection, minutes: Int) throws {
        guard isAuthorized, minutes > 0 else { return }
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            center.stopMonitoring([UnboundShared.Activity.appLimits])
            return
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: minutes)
        )

        try center.startMonitoring(
            UnboundShared.Activity.appLimits,
            during: schedule,
            events: [DeviceActivityEvent.Name("appLimitThreshold"): event]
        )
    }

    func stopAppLimitMonitoring() {
        center.stopMonitoring([UnboundShared.Activity.appLimits])
        ShieldApplier.clear(ManagedSettingsStore(named: UnboundShared.Store.appLimits))
    }
}
