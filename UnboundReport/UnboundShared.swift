import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

enum UnboundShared {
    static let appGroupID = "group.com.unbound.steadfast"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    enum Keys {
        static let activitySelection = "unbound.activitySelection"
        static let blockingEnabled = "unbound.blockingEnabled"
        static let quickBlockEnd = "unbound.quickBlockEnd"
        static let scheduleEnabled = "unbound.scheduleEnabled"
        static let dailyLimitMinutes = "unbound.dailyLimitMinutes"
        static let alertsEnabled = "unbound.alertsEnabled"
        static let todayTotalSeconds = "unbound.todayTotalSeconds"
        static let yesterdayTotalSeconds = "unbound.yesterdayTotalSeconds"
        static let reportDayStart = "unbound.reportDayStart"
        static let appLimitSelection = "unbound.appLimitSelection"
        static let appLimitMinutes = "unbound.appLimitMinutes"
        static let appLanguage = "steadfast.app.language"
    }

    enum Activity {
        static let schedule = DeviceActivityName("unbound.schedule")
        static let dailyGoal = DeviceActivityName("unbound.dailyGoal")
        static let appLimits = DeviceActivityName("unbound.appLimits")
    }

    enum Store {
        static let schedule = ManagedSettingsStore.Name("unbound.schedule")
        static let quickBlock = ManagedSettingsStore.Name("unbound.quickBlock")
        static let appLimits = ManagedSettingsStore.Name("unbound.appLimits")
    }
}

extension FamilyActivitySelection {
    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(from data: Data?) -> FamilyActivitySelection {
        guard let data,
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return selection
    }
}

enum SharedLocalization {
    static var languageCode: String {
        UnboundShared.defaults.string(forKey: UnboundShared.Keys.appLanguage)
            ?? UserDefaults.standard.string(forKey: UnboundShared.Keys.appLanguage)
            ?? "en"
    }

    static var locale: Locale {
        Locale(identifier: languageCode)
    }

    static func bundle(in host: Bundle = .main) -> Bundle {
        guard let path = host.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return host
        }
        return bundle
    }

    static func text(_ key: String, in host: Bundle = .main) -> String {
        NSLocalizedString(key, tableName: nil, bundle: bundle(in: host), value: key, comment: "")
    }

    static func text(_ key: String, in host: Bundle = .main, _ arguments: CVarArg...) -> String {
        String(format: text(key, in: host), locale: locale, arguments: arguments)
    }
}

enum SharedSelectionStore {
    static var activitySelection: FamilyActivitySelection {
        get { FamilyActivitySelection.decode(from: UnboundShared.defaults.data(forKey: UnboundShared.Keys.activitySelection)) }
        set { UnboundShared.defaults.set(newValue.encoded(), forKey: UnboundShared.Keys.activitySelection) }
    }

    static var appLimitSelection: FamilyActivitySelection {
        get { FamilyActivitySelection.decode(from: UnboundShared.defaults.data(forKey: UnboundShared.Keys.appLimitSelection)) }
        set { UnboundShared.defaults.set(newValue.encoded(), forKey: UnboundShared.Keys.appLimitSelection) }
    }

    static var appLimitMinutes: Int {
        get {
            let value = UnboundShared.defaults.integer(forKey: UnboundShared.Keys.appLimitMinutes)
            return value > 0 ? value : 30
        }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.appLimitMinutes) }
    }

    static var blockingEnabled: Bool {
        get { UnboundShared.defaults.bool(forKey: UnboundShared.Keys.blockingEnabled) }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.blockingEnabled) }
    }

    static var scheduleEnabled: Bool {
        get { UnboundShared.defaults.bool(forKey: UnboundShared.Keys.scheduleEnabled) }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.scheduleEnabled) }
    }

    static var quickBlockEnd: Date? {
        get { UnboundShared.defaults.object(forKey: UnboundShared.Keys.quickBlockEnd) as? Date }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.quickBlockEnd) }
    }

    static var quickBlockActive: Bool {
        (quickBlockEnd ?? .distantPast) > Date()
    }

    static var dailyLimitMinutes: Int {
        get {
            let value = UnboundShared.defaults.integer(forKey: UnboundShared.Keys.dailyLimitMinutes)
            return value > 0 ? value : 150
        }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.dailyLimitMinutes) }
    }

    static var alertsEnabled: Bool {
        get { UnboundShared.defaults.bool(forKey: UnboundShared.Keys.alertsEnabled) }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.alertsEnabled) }
    }

    static var todayTotalSeconds: TimeInterval {
        get { UnboundShared.defaults.double(forKey: UnboundShared.Keys.todayTotalSeconds) }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.todayTotalSeconds) }
    }

    static var yesterdayTotalSeconds: TimeInterval {
        get { UnboundShared.defaults.double(forKey: UnboundShared.Keys.yesterdayTotalSeconds) }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.yesterdayTotalSeconds) }
    }

    static var reportDayStart: Date? {
        get { UnboundShared.defaults.object(forKey: UnboundShared.Keys.reportDayStart) as? Date }
        set { UnboundShared.defaults.set(newValue, forKey: UnboundShared.Keys.reportDayStart) }
    }
}

enum ShieldApplier {
    static func apply(_ selection: FamilyActivitySelection, to store: ManagedSettingsStore) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    static func clear(_ store: ManagedSettingsStore) {
        store.clearAllSettings()
    }
}
