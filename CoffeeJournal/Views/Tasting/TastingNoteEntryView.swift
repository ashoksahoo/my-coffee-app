import SwiftUI
import SwiftData

struct TastingNoteEntryView: View {
    let brewLog: BrewLog
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TastingNoteViewModel()

    var body: some View {
        Form {
            tastingAttributesSection
            flavorNotesSection
            selectedFlavorsSection
            customTagsSection
            notesSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Tasting Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppColors.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    viewModel.save(for: brewLog, in: modelContext)
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primary)
                .disabled(!viewModel.hasChanges)
            }
        }
        .onAppear {
            if let note = brewLog.tastingNote {
                viewModel.loadFromTastingNote(note)
            }
        }
    }

    // MARK: - Tasting Attributes

    private var tastingAttributesSection: some View {
        Section("Tasting Attributes") {
            AttributeSliderView(label: "Acidity", value: $viewModel.acidity)
            AttributeSliderView(label: "Body", value: $viewModel.bodyRating)
            AttributeSliderView(label: "Sweetness", value: $viewModel.sweetness)
        }
    }

    // MARK: - Flavor Notes (Hierarchical Browser)

    private var flavorNotesSection: some View {
        Section("Flavor Notes") {
            ForEach(FlavorWheel.categories) { category in
                DisclosureGroup(category.name) {
                    if category.isLeaf {
                        flavorLeafRow(category)
                    } else {
                        ForEach(category.children) { subcategory in
                            if subcategory.isLeaf {
                                flavorLeafRow(subcategory)
                            } else {
                                DisclosureGroup(subcategory.name) {
                                    ForEach(subcategory.children) { descriptor in
                                        flavorLeafRow(descriptor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func flavorLeafRow(_ node: FlavorNode) -> some View {
        Button {
            viewModel.toggleFlavor(node.id)
        } label: {
            HStack {
                Text(node.name)
                    .foregroundStyle(AppColors.primary)
                Spacer()
                if viewModel.selectedFlavorIds.contains(node.id) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }

    // MARK: - Selected Flavors

    @ViewBuilder
    private var selectedFlavorsSection: some View {
        let displayTags = viewModel.allDisplayTags
        if !displayTags.isEmpty {
            Section("Selected Flavors") {
                FlavorTagFlowView(
                    tags: displayTags.map { tag in
                        (id: tag.id, name: tag.name, isCustom: tag.id.hasPrefix("custom:"))
                    },
                    onToggle: { id in
                        if id.hasPrefix("custom:") {
                            viewModel.removeCustomTag(id)
                        } else {
                            viewModel.toggleFlavor(id)
                        }
                    },
                    onRemoveCustom: { id in
                        viewModel.removeCustomTag(id)
                    }
                )
            }
        }
    }

    // MARK: - Custom Tags

    private var customTagsSection: some View {
        Section("Custom Tags") {
            HStack {
                TextField("Add custom flavor...", text: $viewModel.customTagInput)
                    .textInputAutocapitalization(.never)

                Button("Add") {
                    viewModel.addCustomTag()
                }
                .foregroundStyle(AppColors.primary)
                .disabled(viewModel.customTagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        Section("Notes") {
            ZStack(alignment: .topLeading) {
                if viewModel.freeformNotes.isEmpty {
                    Text("Add tasting notes...")
                        .foregroundStyle(AppColors.muted)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $viewModel.freeformNotes)
                    .frame(minHeight: 80)
            }
        }
    }
}
