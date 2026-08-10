import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case arabic = "ar"
    case chineseSimplified = "zh-Hans"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case french = "fr"
    case german = "de"
    case greek = "el"
    case hebrew = "he"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case portuguesePT = "pt-PT"
    case romanian = "ro"
    case russian = "ru"
    case spanishUS = "es-US"
    case swedish = "sv"
    case turkish = "tr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        case .chineseSimplified: return "简体中文"
        case .czech: return "Čeština"
        case .danish: return "Dansk"
        case .dutch: return "Nederlands"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .greek: return "Ελληνικά"
        case .hebrew: return "עברית"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .portuguesePT: return "Português"
        case .romanian: return "Română"
        case .russian: return "Русский"
        case .spanishUS: return "Español"
        case .swedish: return "Svenska"
        case .turkish: return "Türkçe"
        }
    }

    var englishName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "Arabic"
        case .chineseSimplified: return "Chinese (Simplified)"
        case .czech: return "Czech"
        case .danish: return "Danish"
        case .dutch: return "Dutch"
        case .french: return "French"
        case .german: return "German"
        case .greek: return "Greek"
        case .hebrew: return "Hebrew"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .portuguesePT: return "Portuguese"
        case .romanian: return "Romanian"
        case .russian: return "Russian"
        case .spanishUS: return "Spanish"
        case .swedish: return "Swedish"
        case .turkish: return "Turkish"
        }
    }

    var nativeDisplayName: String {
        englishName == displayName ? displayName : "\(englishName) · \(displayName)"
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .arabic: return "🇸🇦"
        case .chineseSimplified: return "🇨🇳"
        case .czech: return "🇨🇿"
        case .danish: return "🇩🇰"
        case .dutch: return "🇳🇱"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .greek: return "🇬🇷"
        case .hebrew: return "🇮🇱"
        case .italian: return "🇮🇹"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .portuguesePT: return "🇵🇹"
        case .romanian: return "🇷🇴"
        case .russian: return "🇷🇺"
        case .spanishUS: return "🇪🇸"
        case .swedish: return "🇸🇪"
        case .turkish: return "🇹🇷"
        }
    }

    var isRTL: Bool {
        switch self {
        case .arabic, .hebrew: return true
        default: return false
        }
    }

    static var pickerLanguages: [AppLanguage] {
        [.english] + allCases.filter { $0 != .english }.sorted { $0.englishName < $1.englishName }
    }

    static func resolve(_ code: String?) -> AppLanguage {
        guard let code, !code.isEmpty else { return .english }
        if let exact = AppLanguage(rawValue: code) { return exact }

        let normalized = code.replacingOccurrences(of: "_", with: "-")
        if let exact = AppLanguage(rawValue: normalized) { return exact }

        let base = normalized.split(separator: "-").first.map(String.init) ?? normalized
        switch base {
        case "en": return .english
        case "ar": return .arabic
        case "zh": return .chineseSimplified
        case "cs": return .czech
        case "da": return .danish
        case "nl": return .dutch
        case "fr": return .french
        case "de": return .german
        case "el": return .greek
        case "he": return .hebrew
        case "it": return .italian
        case "ja": return .japanese
        case "ko": return .korean
        case "pt": return .portuguesePT
        case "ro": return .romanian
        case "ru": return .russian
        case "es": return .spanishUS
        case "sv": return .swedish
        case "tr": return .turkish
        default: return .english
        }
    }
}

@Observable
final class LanguageStore {
    static let storageKey = UnboundShared.Keys.appLanguage
    private(set) static var active: LanguageStore?

    var current: AppLanguage {
        didSet {
            guard current != oldValue else { return }
            persist(current)
            bundle = Self.bundle(for: current)
            NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
        }
    }

    private(set) var bundle: Bundle

    init() {
        let savedCode = UnboundShared.defaults.string(forKey: Self.storageKey)
            ?? UserDefaults.standard.string(forKey: Self.storageKey)
        let deviceCode = Locale.preferredLanguages.first
        let resolved = AppLanguage.resolve(savedCode ?? deviceCode)
        current = resolved
        bundle = Self.bundle(for: resolved)
        persist(resolved)
        Self.active = self
    }

    var layoutDirection: LayoutDirection {
        current.isRTL ? .rightToLeft : .leftToRight
    }

    var locale: Locale {
        Locale(identifier: current.rawValue)
    }

    static func bundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    private func persist(_ language: AppLanguage) {
        UnboundShared.defaults.set(language.rawValue, forKey: Self.storageKey)
        UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
    }

    func text(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }

    func text(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }
}

/// Localized string lookup using the active in-app language.
func L(_ key: String) -> String {
    LanguageStore.active?.text(key) ?? SharedLocalization.text(key)
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    if let store = LanguageStore.active {
        return store.text(key, arguments)
    }
    return SharedLocalization.text(key, arguments)
}
