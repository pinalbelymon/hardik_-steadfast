import SwiftUI

extension View {
    func premiumPaywall(isPresented: Binding<Bool>) -> some View {
        fullScreenCover(isPresented: isPresented) {
            PaywallView()
        }
    }
}

enum PremiumGate {
    @MainActor
    static func openTools(showPaywall: Binding<Bool>, premium: PremiumStore, action: () -> Void) {
        if premium.canAccessTools {
            action()
        } else {
            showPaywall.wrappedValue = true
        }
    }

    @MainActor
    static func openQuest(showPaywall: Binding<Bool>, premium: PremiumStore, action: () -> Void) {
        if premium.canAccessTodaysQuest {
            action()
        } else {
            showPaywall.wrappedValue = true
        }
    }
}
