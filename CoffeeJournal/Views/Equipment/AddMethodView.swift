import SwiftUI
import SwiftData

struct AddMethodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingCustomForm = false
    @State private var customName = ""
    @State private var customCategory: MethodCategory = .other

    var body: some View {
        List {
            Section {
                ForEach(MethodTemplate.curatedMethods) { template in
                    Button {
                        addFromTemplate(template)
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: template.category.iconName)
                                .font(.title3)
                                .foregroundStyle(AppColors.subtle)
                                .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(template.name)
                                    .font(AppTypography.headline)
                                    .foregroundStyle(AppColors.primary)

                                Text(template.category.displayName)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.subtle)
                            }
                        }
                    }
                }
            } header: {
                Text("Popular Methods")
            }

            Section {
                if showingCustomForm {
                    TextField("Method Name", text: $customName)
                        .font(AppTypography.body)

                    Picker("Category", selection: $customCategory) {
                        ForEach(MethodCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }

                    Button {
                        addCustomMethod()
                    } label: {
                        Text("Save")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.primary)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                } else {
                    Button {
                        showingCustomForm = true
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                                .foregroundStyle(AppColors.subtle)
                                .frame(width: 32, height: 32)

                            Text("Custom Method")
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                }
            } header: {
                Text("Custom")
            }
        }
        .navigationTitle("Add Brew Method")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppColors.primary)
            }
        }
    }

    private func addFromTemplate(_ template: MethodTemplate) {
        let method = BrewMethod(from: template)
        modelContext.insert(method)
        dismiss()
    }

    private func addCustomMethod() {
        let trimmedName = customName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let method = BrewMethod(name: trimmedName, category: customCategory)
        modelContext.insert(method)
        dismiss()
    }
}
