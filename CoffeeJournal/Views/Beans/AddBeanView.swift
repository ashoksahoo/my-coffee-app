import SwiftUI
import SwiftData

struct AddBeanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var roaster = ""
    @State private var origin = ""
    @State private var region = ""
    @State private var variety = ""
    @State private var selectedProcessingMethod: ProcessingMethod = .other
    @State private var selectedRoastLevel: RoastLevel = .medium
    @State private var hasRoastDate = false
    @State private var roastDate = Date()
    @State private var notes = ""

    private var canSave: Bool {
        !roaster.trimmingCharacters(in: .whitespaces).isEmpty &&
        !origin.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            coffeeInfoSection
            originDetailsSection
            roastSection
            notesSection
        }
        .navigationTitle("Add Coffee")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppColors.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveBean()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primary)
                .disabled(!canSave)
            }
        }
    }

    // MARK: - Coffee Info

    @ViewBuilder
    private var coffeeInfoSection: some View {
        Section("Coffee Info") {
            TextField("Name (optional)", text: $name)
                .font(AppTypography.body)

            TextField("Roaster", text: $roaster)
                .font(AppTypography.body)

            TextField("Origin", text: $origin)
                .font(AppTypography.body)
        }
    }

    // MARK: - Origin Details

    @ViewBuilder
    private var originDetailsSection: some View {
        Section("Origin Details") {
            TextField("Region (optional)", text: $region)
                .font(AppTypography.body)

            TextField("Variety (optional)", text: $variety)
                .font(AppTypography.body)
        }
    }

    // MARK: - Roast

    @ViewBuilder
    private var roastSection: some View {
        Section("Roast") {
            Picker("Roast Level", selection: $selectedRoastLevel) {
                ForEach(RoastLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }

            Picker("Processing", selection: $selectedProcessingMethod) {
                ForEach(ProcessingMethod.allCases, id: \.self) { method in
                    Text(method.displayName).tag(method)
                }
            }

            Toggle("Roast Date", isOn: $hasRoastDate)

            if hasRoastDate {
                DatePicker(
                    "Roasted On",
                    selection: $roastDate,
                    displayedComponents: .date
                )
            }
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .font(AppTypography.body)
                .lineLimit(3...6)
        }
    }

    // MARK: - Save

    private func saveBean() {
        let trimmedRoaster = roaster.trimmingCharacters(in: .whitespaces)
        let trimmedOrigin = origin.trimmingCharacters(in: .whitespaces)
        guard !trimmedRoaster.isEmpty && !trimmedOrigin.isEmpty else { return }

        let bean = CoffeeBean()
        bean.name = name.trimmingCharacters(in: .whitespaces)
        bean.roaster = trimmedRoaster
        bean.origin = trimmedOrigin
        bean.region = region.trimmingCharacters(in: .whitespaces)
        bean.variety = variety.trimmingCharacters(in: .whitespaces)
        bean.roastLevel = selectedRoastLevel.rawValue
        bean.processingMethod = selectedProcessingMethod.rawValue
        bean.roastDate = hasRoastDate ? roastDate : nil
        bean.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        modelContext.insert(bean)
        dismiss()
    }
}
