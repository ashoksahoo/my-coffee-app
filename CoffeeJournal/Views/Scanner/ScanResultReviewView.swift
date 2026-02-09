import SwiftUI
import SwiftData

struct ScanResultReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var roaster: String
    @State private var origin: String
    @State private var region: String
    @State private var variety: String
    @State private var selectedRoastLevel: RoastLevel
    @State private var selectedProcessingMethod: ProcessingMethod
    @State private var hasRoastDate: Bool
    @State private var roastDate: Date
    @State private var notes: String = ""

    init(parsedLabel: ParsedBagLabel) {
        _roaster = State(initialValue: parsedLabel.roaster ?? "")
        _origin = State(initialValue: parsedLabel.origin ?? "")
        _region = State(initialValue: parsedLabel.region ?? "")
        _variety = State(initialValue: parsedLabel.variety ?? "")
        _selectedRoastLevel = State(
            initialValue: RoastLevel(rawValue: parsedLabel.roastLevel ?? "") ?? .medium
        )
        _selectedProcessingMethod = State(
            initialValue: ProcessingMethod(rawValue: parsedLabel.processingMethod ?? "") ?? .other
        )
        _hasRoastDate = State(initialValue: parsedLabel.roastDate != nil)
        _roastDate = State(initialValue: parsedLabel.roastDate ?? Date())
    }

    private var canSave: Bool {
        !roaster.trimmingCharacters(in: .whitespaces).isEmpty ||
        !origin.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            scannedHeaderSection
            coffeeInfoSection
            originDetailsSection
            roastSection
            notesSection
        }
        .navigationTitle("Review Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppColors.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save Coffee") {
                    saveCoffee()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primary)
                .disabled(!canSave)
            }
        }
    }

    // MARK: - Scanned Header

    @ViewBuilder
    private var scannedHeaderSection: some View {
        Section {
            Text("Review and correct the extracted information")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.subtle)
        } header: {
            Text("Scanned Results")
        }
    }

    // MARK: - Coffee Info

    @ViewBuilder
    private var coffeeInfoSection: some View {
        Section("Coffee Info") {
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

    private func saveCoffee() {
        let bean = CoffeeBean()
        bean.roaster = roaster.trimmingCharacters(in: .whitespaces)
        bean.origin = origin.trimmingCharacters(in: .whitespaces)
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
