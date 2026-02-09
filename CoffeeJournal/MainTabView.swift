import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("Home")
                    .navigationTitle("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                Text("Settings")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    MainTabView()
}
