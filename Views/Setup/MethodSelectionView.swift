import SwiftUI

struct MethodSelectionView: View {
    @Binding var selectedMethods: Set<MethodTemplate>

    private let methods = MethodTemplate.curatedMethods

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Header
            VStack(spacing: AppSpacing.xs) {
                Text("Select Your Brew Methods")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.primary)

                Text("\(selectedMethods.count) method\(selectedMethods.count == 1 ? "" : "s") selected")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
            }
            .padding(.top, AppSpacing.md)

            // Method list
            ScrollView {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(methods) { method in
                        MethodSelectionRow(
                            template: method,
                            isSelected: selectedMethods.contains(method)
                        ) {
                            toggleMethod(method)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    private func toggleMethod(_ method: MethodTemplate) {
        if selectedMethods.contains(method) {
            selectedMethods.remove(method)
        } else {
            selectedMethods.insert(method)
        }
    }
}

// MARK: - Method Selection Row

private struct MethodSelectionRow: View {
    let template: MethodTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Method icon
                Image(systemName: template.iconName)
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 32, height: 32)

                // Method info
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.primary)

                    Text(categoryLabel(for: template.category))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.muted)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? AppColors.primary : AppColors.muted,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryLabel(for category: MethodCategory) -> String {
        switch category {
        case .espresso:
            return "Espresso"
        case .pourOver:
            return "Pour Over"
        case .immersion:
            return "Immersion"
        case .other:
            return "Other"
        }
    }
}
