import SwiftUI
import SwiftData

struct MethodDetailView: View {
    @Bindable var method: BrewMethod
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            photoSection
            detailsSection
            parametersSection
            statisticsSection
        }
        .navigationTitle(method.name)
        .onChange(of: method.name) { _, _ in
            method.updatedAt = Date()
        }
        .onChange(of: method.notes) { _, _ in
            method.updatedAt = Date()
        }
    }

    // MARK: - Photo + Name

    @ViewBuilder
    private var photoSection: some View {
        Section {
            EquipmentPhotoPickerView(photoData: $method.photoData)
                .listRowInsets(EdgeInsets(top: AppSpacing.sm, leading: AppSpacing.md, bottom: AppSpacing.sm, trailing: AppSpacing.md))

            TextField("Method Name", text: $method.name)
                .font(AppTypography.title)
        }
    }

    // MARK: - Details

    @ViewBuilder
    private var detailsSection: some View {
        Section("Details") {
            LabeledContent("Category") {
                Text(method.category.displayName)
                    .foregroundStyle(AppColors.secondary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Notes")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
                TextEditor(text: $method.notes)
                    .frame(minHeight: 80)
            }
        }
    }

    // MARK: - Brew Parameters (read-only)

    @ViewBuilder
    private var parametersSection: some View {
        Section {
            ForEach(parametersForCategory(method.category), id: \.name) { param in
                HStack {
                    Text(param.name)
                        .font(AppTypography.body)
                    Spacer()
                    Text(param.isRequired ? "Required" : "Optional")
                        .font(AppTypography.caption)
                        .foregroundStyle(param.isRequired ? AppColors.primary : AppColors.muted)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.secondaryBackground)
                        )
                }
            }
        } header: {
            Text("Brew Parameters")
        } footer: {
            Text("Parameters are used when logging brews with this method")
                .font(AppTypography.footnote)
        }
    }

    // MARK: - Usage Statistics

    @ViewBuilder
    private var statisticsSection: some View {
        Section("Usage Statistics") {
            if method.brewCount > 0 {
                LabeledContent("Brews") {
                    Text("\(method.brewCount) brews")
                }
                LabeledContent("Last Used") {
                    if let lastUsed = method.lastUsedDate {
                        Text(lastUsed, style: .relative)
                            .foregroundStyle(AppColors.secondary)
                    } else {
                        Text("Never used")
                            .foregroundStyle(AppColors.muted)
                    }
                }
            } else {
                Text("Use this method in a brew to see stats here")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
            }

            LabeledContent("Created") {
                Text(method.createdAt, style: .date)
                    .foregroundStyle(AppColors.secondary)
            }
        }
    }

    // MARK: - Parameter Definitions

    private struct BrewParameter {
        let name: String
        let isRequired: Bool
    }

    private func parametersForCategory(_ category: MethodCategory) -> [BrewParameter] {
        switch category {
        case .espresso:
            return [
                BrewParameter(name: "Dose (g)", isRequired: true),
                BrewParameter(name: "Yield (g)", isRequired: true),
                BrewParameter(name: "Time", isRequired: true),
                BrewParameter(name: "Water Temperature", isRequired: true),
                BrewParameter(name: "Pressure Profile", isRequired: false),
            ]
        case .pourOver:
            return [
                BrewParameter(name: "Dose (g)", isRequired: true),
                BrewParameter(name: "Water Amount (g)", isRequired: true),
                BrewParameter(name: "Time", isRequired: true),
            ]
        case .immersion, .other:
            return [
                BrewParameter(name: "Dose (g)", isRequired: true),
                BrewParameter(name: "Water Amount (g)", isRequired: true),
                BrewParameter(name: "Time", isRequired: true),
                BrewParameter(name: "Water Temperature", isRequired: true),
            ]
        }
    }
}
