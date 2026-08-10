import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label(L("tab.home"), systemImage: "house.fill") }

            NavigationStack {
                UserProgressView()
            }
            .tabItem { Label(L("tab.progress"), systemImage: "chart.bar.fill") }

            NavigationStack {
                ToolsView()
            }
            .tabItem { Label(L("tab.tools"), systemImage: "wrench.and.screwdriver.fill") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(L("tab.settings"), systemImage: "gearshape.fill") }
        }
        .dismissKeyboardOnTap()
    }
}
