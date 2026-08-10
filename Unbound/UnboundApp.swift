//
//  UnboundApp.swift
//  Unbound
//
//  Created by hardik on 08/08/26.
//

import SwiftUI

@main
struct UnboundApp: App {
    @State private var store = AppStore()
    @State private var blockingStore = BlockingStore()
    @State private var exerciseStore = ExerciseStore()
    @State private var screenTimeStore = ScreenTimeStore()
    @State private var premiumStore = PremiumStore()

    @State private var languageStore = LanguageStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(blockingStore)
                .environment(exerciseStore)
                .environment(screenTimeStore)
                .environment(premiumStore)
                .environment(languageStore)
                .environment(\.locale, languageStore.locale)
                .environment(\.layoutDirection, languageStore.layoutDirection)
                .id(languageStore.current.rawValue)
                .tint(Theme.accent)
                .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
                    store.refreshLocalizedNotifications()
                }
                .task {
                    ScreenTimeKitManager.shared.refreshStatus()
                    screenTimeStore.refreshFromSharedDefaults()
                    if ScreenTimeKitManager.shared.isAuthorized {
                        screenTimeStore.bootstrapMonitoring()
                    }
                }
        }
    }
}

private struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .fullScreenCover(item: celebrationBinding) { milestone in
            MilestoneCelebrationView(milestone: milestone) {
                store.dismissMilestoneCelebration()
            }
        }
    }

    private var celebrationBinding: Binding<Milestone?> {
        Binding(
            get: { store.celebrationMilestone },
            set: { newValue in
                if newValue == nil {
                    store.dismissMilestoneCelebration()
                }
            }
        )
    }
}
