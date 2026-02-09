import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BeanListView()
            }
            .tabItem {
                Label("Beans", systemImage: "leaf")
            }

            NavigationStack {
                MethodListView()
            }
            .tabItem {
                Label("Methods", systemImage: "cup.and.saucer")
            }

            NavigationStack {
                GrinderListView()
            }
            .tabItem {
                Label("Grinders", systemImage: "gearshape.2")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(Color.primary)
    }
}

#Preview {
    MainTabView()
}
