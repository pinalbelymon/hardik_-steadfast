import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

final class UnboundDeviceActivityMonitor: DeviceActivityMonitor {
    private let scheduleStore = ManagedSettingsStore(named: UnboundShared.Store.schedule)
    private let appLimitStore = ManagedSettingsStore(named: UnboundShared.Store.appLimits)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        switch activity {
        case UnboundShared.Activity.schedule:
            guard SharedSelectionStore.blockingEnabled || SharedSelectionStore.scheduleEnabled else { return }
            ShieldApplier.apply(SharedSelectionStore.activitySelection, to: scheduleStore)
        default:
            break
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        switch activity {
        case UnboundShared.Activity.schedule:
            if SharedSelectionStore.quickBlockActive { return }
            ShieldApplier.clear(scheduleStore)
        case UnboundShared.Activity.dailyGoal, UnboundShared.Activity.appLimits:
            // Threshold windows reset daily; keep limit shields until next day start.
            break
        default:
            break
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        switch activity {
        case UnboundShared.Activity.appLimits:
            ShieldApplier.apply(SharedSelectionStore.appLimitSelection, to: appLimitStore)
        case UnboundShared.Activity.dailyGoal:
            // Goal reached — optional: notify via local notification extension path.
            break
        default:
            break
        }
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }
}
