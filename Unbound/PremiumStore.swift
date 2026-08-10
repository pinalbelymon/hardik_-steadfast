import Foundation
import Observation
import StoreKit

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return L("subscription.weekly")
        case .monthly: return L("subscription.monthly")
        case .yearly: return L("subscription.yearly")
        }
    }

    var productID: String {
        switch self {
        case .weekly: return "com.unbound.steadfast.premium.weekly"
        case .monthly: return "com.unbound.steadfast.premium.monthly"
        case .yearly: return "com.unbound.steadfast.premium.yearly"
        }
    }

    var fallbackPrice: String {
        switch self {
        case .weekly: return "$4.99"
        case .monthly: return "$9.99"
        case .yearly: return "$49.99"
        }
    }

    var periodLabel: String {
        switch self {
        case .weekly: return L("subscription.per_week")
        case .monthly: return L("subscription.per_month")
        case .yearly: return L("subscription.per_year")
        }
    }

    var badge: String? {
        switch self {
        case .monthly: return L("subscription.badge.popular")
        case .yearly: return L("subscription.badge.best_value")
        case .weekly: return nil
        }
    }
}

enum LegalLinks {
    static let privacyPolicy = URL(string: "https://belymoninfotech.com/app/steadfast/privacypolicy.html")!
    static let termsOfUse = URL(string: "https://belymoninfotech.com/app/steadfast/termsofuse.html")!
    static let appleEULA = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

enum SupportMail {
    static let address = "hardikgoyani1@gmail.com"

    static func contactURL(currentStreak: Int, bestStreak: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: L("support.mail.subject")),
            URLQueryItem(name: "body", value: prefilledBody(currentStreak: currentStreak, bestStreak: bestStreak))
        ]
        return components.url
    }

    private static func prefilledBody(currentStreak: Int, bestStreak: Int) -> String {
        """
        \(L("support.mail.greeting"))

        \(L("support.mail.help_line"))


        \(L("support.mail.describe"))


        ---
        \(L("support.mail.footer_app"))
        \(L("support.mail.current_streak", currentStreak))
        \(L("support.mail.best_streak", bestStreak))
        """
    }
}

@Observable
@MainActor
final class PremiumStore {
    private static let installDateKey = "steadfast.installDate"
    private static let premiumOverrideKey = "steadfast.premium.override"

    private(set) var installDate: Date
    private(set) var products: [Product] = []
    private(set) var activePlan: SubscriptionPlan?
    var selectedPlan: SubscriptionPlan = .monthly
    var isPremium = false
    var isLoadingProducts = false
    var isPurchasing = false
    var purchaseMessage: String?

    init() {
        if let saved = UserDefaults.standard.object(forKey: Self.installDateKey) as? Date {
            installDate = saved
        } else {
            installDate = Date()
            UserDefaults.standard.set(installDate, forKey: Self.installDateKey)
        }

        if UserDefaults.standard.bool(forKey: Self.premiumOverrideKey) {
            isPremium = true
        }

        Task {
            await loadProducts()
            await refreshEntitlements()
            listenForTransactions()
        }
    }

    var isFirstInstallDay: Bool {
        Calendar.current.isDate(Date(), inSameDayAs: installDate)
    }

    /// Tools are always premium — no free trial day.
    var canAccessTools: Bool { isPremium }

    /// Today's Quest is free only on the first calendar day after install.
    var canAccessTodaysQuest: Bool { isPremium || isFirstInstallDay }

    func price(for plan: SubscriptionPlan) -> String {
        products.first(where: { $0.id == plan.productID })?.displayPrice ?? plan.fallbackPrice
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        products.first(where: { $0.id == plan.productID })
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: SubscriptionPlan.allCases.map(\.productID))
                .sorted { lhs, rhs in
                    order(for: lhs.id) < order(for: rhs.id)
                }
        } catch {
            purchaseMessage = L("purchase.error.load_plans")
        }
    }

    func purchaseSelectedPlan() async -> Bool {
        guard let product = product(for: selectedPlan) else {
            purchaseMessage = L("purchase.error.unavailable")
            return false
        }
        isPurchasing = true
        purchaseMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    purchaseMessage = nil
                    return isPremium
                }
                return false
            case .userCancelled:
                return false
            case .pending:
                purchaseMessage = L("purchase.error.pending")
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseMessage = L("purchase.error.failed")
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isPurchasing = true
        purchaseMessage = nil
        defer { isPurchasing = false }
        do {
            try await StoreKit.AppStore.sync()
            await refreshEntitlements()
            purchaseMessage = isPremium ? nil : L("purchase.error.no_subscription")
            return isPremium
        } catch {
            purchaseMessage = L("purchase.error.restore_failed")
            return false
        }
    }

    var activePlanTitle: String {
        activePlan?.title ?? L("common.premium")
    }

    var activePlanDetail: String? {
        guard let activePlan else { return nil }
        return "\(price(for: activePlan)) \(activePlan.periodLabel)"
    }

    func refreshEntitlements() async {
        var active = UserDefaults.standard.bool(forKey: Self.premiumOverrideKey)
        var plan: SubscriptionPlan?

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               let matched = SubscriptionPlan.allCases.first(where: { $0.productID == transaction.productID }),
               transaction.revocationDate == nil {
                active = true
                plan = matched
            }
        }

        isPremium = active
        activePlan = plan
        if let plan {
            selectedPlan = plan
        }
    }

    private func listenForTransactions() {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            }
        }
    }

    private func order(for productID: String) -> Int {
        switch productID {
        case SubscriptionPlan.weekly.productID: return 0
        case SubscriptionPlan.monthly.productID: return 1
        default: return 2
        }
    }
}
