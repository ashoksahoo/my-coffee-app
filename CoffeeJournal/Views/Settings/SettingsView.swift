import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage(AppStorageKeys.appearanceMode) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @State private var showingSetupWizard = false
    @State private var wizardViewModel = SetupWizardViewModel()
    #if DEBUG
    @Environment(\.modelContext) private var modelContext
    @State private var seedConfirmation = false
    @State private var seedDone = false
    #endif

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

            #if DEBUG
            Section {
                Button {
                    seedConfirmation = true
                } label: {
                    Label("Load Sample Data", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Developer")
            } footer: {
                Text("Seeds 30+ brew logs with tasting notes to test Foundation Models insights. Only loads if no brews exist.")
            }
            #endif
        }
        .navigationTitle("Settings")
        #if DEBUG
        .alert("Load Sample Data?", isPresented: $seedConfirmation) {
            Button("Load", role: .destructive) {
                SeedDataService.seed(into: modelContext)
                seedDone = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will add 5 beans, 3 brew methods, and 30+ brew logs with rich tasting notes. Only runs if your brew list is empty.")
        }
        .alert("Sample Data Loaded", isPresented: $seedDone) {
            Button("OK") {}
        } message: {
            Text("30+ brew logs added. Go to Brews or Statistics to see the Foundation Models insights in action.")
        }
        #endif
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
