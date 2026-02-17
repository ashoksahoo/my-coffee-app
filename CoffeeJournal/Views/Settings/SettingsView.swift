import SwiftUI

struct SettingsView: View {
    @AppStorage(AppStorageKeys.appearanceMode) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @State private var showingSetupWizard = false
    @State private var wizardViewModel = SetupWizardViewModel()

    private var appearanceMode: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .system },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button {
                    wizardViewModel.reset()
                    showingSetupWizard = true
                } label: {
                    Label("Re-run Setup Wizard", systemImage: "wand.and.stars")
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityIdentifier(AccessibilityID.Settings.rerunWizardButton)
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
