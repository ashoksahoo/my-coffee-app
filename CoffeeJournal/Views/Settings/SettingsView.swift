import SwiftUI

struct SettingsView: View {
    @Environment(SyncMonitor.self) private var syncMonitor
    @State private var showingSetupWizard = false
    @State private var wizardViewModel = SetupWizardViewModel()

    var body: some View {
        Form {
            Section {
                Button {
                    wizardViewModel.reset()
                    showingSetupWizard = true
                } label: {
                    Label("Re-run Setup Wizard", systemImage: "wand.and.stars")
                        .foregroundStyle(AppColors.primary)
                }
            } header: {
                Text("Equipment Setup")
            } footer: {
                Text("Add more brew methods and grinders from the curated list")
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(AppColors.subtle)
                }

                HStack {
                    Text("Coffee Journal")
                    Spacer()
                    Text("Remember every brew")
                        .foregroundStyle(AppColors.subtle)
                }
            }

            SyncStatusSection()
        }
        .navigationTitle("Settings")
        .task {
            await syncMonitor.checkAccountStatus()
        }
        .sheet(isPresented: $showingSetupWizard) {
            SetupWizardView(onComplete: {
                showingSetupWizard = false
            })
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
