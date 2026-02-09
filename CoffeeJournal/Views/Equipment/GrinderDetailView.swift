import SwiftUI
import SwiftData

struct GrinderDetailView: View {
    @Bindable var grinder: Grinder
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            photoSection
            detailsSection
            settingRangeSection
            notesSection
            statisticsSection
        }
        .navigationTitle(grinder.name)
        .onChange(of: grinder.name) { _, _ in
            grinder.updatedAt = Date()
        }
        .onChange(of: grinder.notes) { _, _ in
            grinder.updatedAt = Date()
        }
        .onChange(of: grinder.typeRawValue) { _, _ in
            grinder.updatedAt = Date()
        }
        .onChange(of: grinder.settingMin) { _, _ in
            grinder.updatedAt = Date()
        }
        .onChange(of: grinder.settingMax) { _, _ in
            grinder.updatedAt = Date()
        }
        .onChange(of: grinder.settingStep) { _, _ in
            grinder.updatedAt = Date()
        }
    }

    // MARK: - Photo + Name

    @ViewBuilder
    private var photoSection: some View {
        Section {
            photoArea
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .listRowInsets(EdgeInsets())

            TextField("Grinder Name", text: $grinder.name)
                .font(AppTypography.title)
        }
    }

    @ViewBuilder
    private var photoArea: some View {
        if let photoData = grinder.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.secondaryBackground)
                Image(systemName: grinder.grinderType.iconName)
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.subtle)
            }
        }
    }

    // MARK: - Details

    @ViewBuilder
    private var detailsSection: some View {
        Section("Details") {
            Picker("Type", selection: $grinder.typeRawValue) {
                ForEach(GrinderType.allCases, id: \.rawValue) { type in
                    Text(type.displayName).tag(type.rawValue)
                }
            }
        }
    }

    // MARK: - Setting Range

    @ViewBuilder
    private var settingRangeSection: some View {
        Section {
            Stepper("Min: \(grinder.settingMin, specifier: "%.1f")", value: $grinder.settingMin, in: 0...grinder.settingMax, step: grinder.settingStep)

            Stepper("Max: \(grinder.settingMax, specifier: "%.1f")", value: $grinder.settingMax, in: grinder.settingMin...1000, step: grinder.settingStep)

            Stepper("Step: \(grinder.settingStep, specifier: "%.1f")", value: $grinder.settingStep, in: 0.1...10, step: 0.1)

            HStack {
                Text("Preview")
                    .foregroundStyle(AppColors.subtle)
                Spacer()
                Text("Range: \(grinder.settingMin, specifier: "%.0f") - \(grinder.settingMax, specifier: "%.0f"), step \(grinder.settingStep, specifier: "%.1f")")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)
            }
        } header: {
            Text("Setting Range")
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $grinder.notes)
                .frame(minHeight: 80)
        }
    }

    // MARK: - Usage Statistics

    @ViewBuilder
    private var statisticsSection: some View {
        Section("Usage Statistics") {
            if grinder.brewCount > 0 {
                LabeledContent("Brews") {
                    Text("\(grinder.brewCount) brews")
                }
                LabeledContent("Last Used") {
                    if let lastUsed = grinder.lastUsedDate {
                        Text(lastUsed, style: .relative)
                            .foregroundStyle(AppColors.secondary)
                    } else {
                        Text("Never used")
                            .foregroundStyle(AppColors.muted)
                    }
                }
            } else {
                Text("Use this grinder in a brew to see stats here")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
            }

            LabeledContent("Created") {
                Text(grinder.createdAt, style: .date)
                    .foregroundStyle(AppColors.secondary)
            }
        }
    }
}
