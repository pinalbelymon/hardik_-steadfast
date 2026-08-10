//
//  ContentView.swift
//  Unbound
//
//  Created by hardik on 08/08/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) private var store

    private var appPhase: Int {
        if !store.hasCompletedOnboarding { return 0 }
        if !store.hasCompletedIntro { return 1 }
        return 2
    }

    var body: some View {
        Group {
            switch appPhase {
            case 0:
                OnboardingView()
                    .transition(.opacity)
            case 1:
                PostOnboardingIntroView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.02)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
            default:
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.55), value: appPhase)
    }
}

#Preview {
    ContentView()
        .environment(AppStore())
        .environment(BlockingStore())
        .environment(ExerciseStore())
        .environment(ScreenTimeStore())
        .environment(PremiumStore())
        .environment(LanguageStore())
}
