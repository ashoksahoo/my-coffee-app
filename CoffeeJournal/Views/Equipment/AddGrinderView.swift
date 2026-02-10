import SwiftUI
import SwiftData

struct AddGrinderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedType: GrinderType = .burr
    @State private var settingMin: Double = 0
    @State private var settingMax: Double = 40
    @State private var settingStep: Double = 1
    @State private var notes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("Grinder Name", text: $name)
                    .font(AppTypography.body)
                    .accessibilityIdentifier(AccessibilityID.Equipment.grinderNameField)

                Picker("Type", selection: $selectedType) {
                    ForEach(GrinderType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            } header: {
                Text("Grinder Info")
            }

            Section {
                Stepper(
                    "Minimum: \(formatSetting(settingMin))",
                    value: $settingMin,
                    in: 0...settingMax,
                    step: 1
                )
                .font(AppTypography.body)

                Stepper(
                    "Maximum: \(formatSetting(settingMax))",
                    value: $settingMax,
                    in: settingMin...100,
                    step: 1
                )
                .font(AppTypography.body)

                Stepper(
                    "Step: \(formatSetting(settingStep))",
                    value: $settingStep,
                    in: 0.1...10,
                    step: 0.1
                )
                .font(AppTypography.body)
            } header: {
                Text("Setting Range")
            }

            Section {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .font(AppTypography.body)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle("Add Grinder")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppColors.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveGrinder()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primary)
                .disabled(!canSave)
                .accessibilityIdentifier(AccessibilityID.Equipment.grinderSaveButton)
            }
        }
    }

    private func saveGrinder() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let grinder = Grinder(name: trimmedName, type: selectedType)
        grinder.settingMin = settingMin
        grinder.settingMax = settingMax
        grinder.settingStep = settingStep
        grinder.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        modelContext.insert(grinder)
        dismiss()
    }

    private func formatSetting(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}
