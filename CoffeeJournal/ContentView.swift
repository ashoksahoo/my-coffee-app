import SwiftUI

struct ContentView: View {
    @AppStorage(AppStorageKeys.hasCompletedSetup) private var hasCompletedSetup = false

    var body: some View {
        if hasCompletedSetup {
            MainTabView()
        } else {
            SetupWizardView(onComplete: {
                hasCompletedSetup = true
            })
        }
    }
}

#Preview {
    ContentView()
}
