import SwiftUI
import SwiftData

struct BeanDetailView: View {
    @Bindable var bean: CoffeeBean
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            photoSection
            originSection
            roastSection
            notesSection
            infoSection
        }
        .navigationTitle(bean.displayName)
        .onChange(of: bean.roaster) { _, _ in
            bean.updatedAt = Date()
        }
        .onChange(of: bean.origin) { _, _ in
            bean.updatedAt = Date()
        }
        .onChange(of: bean.roastLevel) { _, _ in
            bean.updatedAt = Date()
        }
        .onChange(of: bean.processingMethod) { _, _ in
            bean.updatedAt = Date()
        }
        .onChange(of: bean.notes) { _, _ in
            bean.updatedAt = Date()
        }
    }

    // MARK: - Photo + Name

    @ViewBuilder
    private var photoSection: some View {
        Section {
            EquipmentPhotoPickerView(photoData: $bean.photoData)
                .listRowInsets(EdgeInsets(top: AppSpacing.sm, leading: AppSpacing.md, bottom: AppSpacing.sm, trailing: AppSpacing.md))

            TextField("Name (optional)", text: $bean.name)
                .font(AppTypography.title)
        }
    }

    // MARK: - Origin

    @ViewBuilder
    private var originSection: some View {
        Section("Origin") {
            TextField("Roaster", text: $bean.roaster)
            TextField("Origin", text: $bean.origin)
            TextField("Region", text: $bean.region)
            TextField("Variety", text: $bean.variety)
        }
    }

    // MARK: - Roast

    @ViewBuilder
    private var roastSection: some View {
        Section("Roast") {
            Picker("Roast Level", selection: $bean.roastLevel) {
                ForEach(RoastLevel.allCases, id: \.rawValue) { level in
                    Text(level.displayName).tag(level.rawValue)
                }
            }

            Picker("Processing", selection: $bean.processingMethod) {
                ForEach(ProcessingMethod.allCases, id: \.rawValue) { method in
                    Text(method.displayName).tag(method.rawValue)
                }
            }

            roastDateRow

            FreshnessIndicatorView(roastDate: bean.roastDate)
        }
    }

    @ViewBuilder
    private var roastDateRow: some View {
        if let _ = bean.roastDate {
            DatePicker(
                "Roast Date",
                selection: Binding(
                    get: { bean.roastDate ?? Date() },
                    set: { bean.roastDate = $0; bean.updatedAt = Date() }
                ),
                displayedComponents: .date
            )

            Button("Clear Roast Date") {
                bean.roastDate = nil
                bean.updatedAt = Date()
            }
            .foregroundStyle(AppColors.subtle)
            .font(AppTypography.caption)
        } else {
            Button("Set Roast Date") {
                bean.roastDate = Date()
                bean.updatedAt = Date()
            }
            .foregroundStyle(AppColors.primary)
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $bean.notes)
                .frame(minHeight: 80)
        }
    }

    // MARK: - Info

    @ViewBuilder
    private var infoSection: some View {
        Section("Info") {
            LabeledContent("Created") {
                Text(bean.createdAt, style: .date)
                    .foregroundStyle(AppColors.secondary)
            }

            Button {
                bean.isArchived.toggle()
                bean.updatedAt = Date()
            } label: {
                Label(
                    bean.isArchived ? "Unarchive" : "Archive",
                    systemImage: bean.isArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }
            .foregroundStyle(AppColors.primary)
        }
    }
}
