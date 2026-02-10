import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BrewLogListView()
            }
            .tabItem {
                Label("Brews", systemImage: "mug")
            }
            .accessibilityIdentifier(AccessibilityID.Tabs.brews)

            NavigationStack {
                BeanListView()
            }
            .tabItem {
                Label("Beans", systemImage: "leaf")
            }
            .accessibilityIdentifier(AccessibilityID.Tabs.beans)

            NavigationStack {
                MethodListView()
            }
            .tabItem {
                Label("Methods", systemImage: "cup.and.saucer")
            }
            .accessibilityIdentifier(AccessibilityID.Tabs.methods)

            NavigationStack {
                GrinderListView()
            }
            .tabItem {
                Label("Grinders", systemImage: "gearshape.2")
            }
            .accessibilityIdentifier(AccessibilityID.Tabs.grinders)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .accessibilityIdentifier(AccessibilityID.Tabs.settings)
        }
        .tint(Color.primary)
    }
}

#Preview {
    MainTabView()
}
