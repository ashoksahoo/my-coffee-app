import SwiftUI
import SwiftData

struct BrewFilterSheet: View {
    @Binding var selectedMethodID: PersistentIdentifier?
    @Binding var selectedBeanID: PersistentIdentifier?
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var minimumRating: Int
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \BrewMethod.name) private var methods: [BrewMethod]
    @Query(filter: #Predicate<CoffeeBean> { !$0.isArchived }, sort: \CoffeeBean.createdAt, order: .reverse) private var beans: [CoffeeBean]

    @State private var dateFilterEnabled: Bool = false

    var body: some View {
        Form {
            Section("Brew Method") {
                Picker("Method", selection: $selectedMethodID) {
                    Text("All Methods").tag(nil as PersistentIdentifier?)
                    ForEach(methods) { method in
                        Text(method.name).tag(Optional(method.persistentModelID))
                    }
                }
            }

            Section("Coffee") {
                Picker("Bean", selection: $selectedBeanID) {
                    Text("All Coffees").tag(nil as PersistentIdentifier?)
                    ForEach(beans) { bean in
                        Text(bean.displayName).tag(Optional(bean.persistentModelID))
                    }
                }
            }

            Section("Date Range") {
                Toggle("Filter by date", isOn: $dateFilterEnabled)
                    .onChange(of: dateFilterEnabled) { _, enabled in
                        if enabled {
                            startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
                            endDate = Date()
                        } else {
                            startDate = nil
                            endDate = nil
                        }
                    }

                if dateFilterEnabled {
                    DatePicker(
                        "From",
                        selection: Binding(
                            get: { startDate ?? Date.distantPast },
                            set: { startDate = $0 }
                        ),
                        displayedComponents: .date
                    )

                    DatePicker(
                        "To",
                        selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
            }

            Section("Minimum Rating") {
                Picker("Rating", selection: $minimumRating) {
                    Text("Any").tag(0)
                    ForEach(1...5, id: \.self) { r in
                        Text("\(r)+ stars").tag(r)
                    }
                }
            }

            Section {
                Button("Clear All Filters") {
                    clearFilters()
                }
                .foregroundStyle(AppColors.secondary)
            }
        }
        .navigationTitle("Filter Brews")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundStyle(AppColors.primary)
            }
        }
        .onAppear {
            dateFilterEnabled = startDate != nil
        }
    }

    private func clearFilters() {
        selectedMethodID = nil
        selectedBeanID = nil
        startDate = nil
        endDate = nil
        minimumRating = 0
        dateFilterEnabled = false
    }
}
