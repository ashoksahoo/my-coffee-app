import SwiftUI

struct SettingsView: View {
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

            Section {
                HStack {
                    Text("iCloud Sync")
                    Spacer()
                    Text("Enabled")
                        .foregroundStyle(AppColors.subtle)
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Your equipment syncs automatically across your iOS devices")
            }
        }
        .navigationTitle("Settings")
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
