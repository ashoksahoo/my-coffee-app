import SwiftUI
import SwiftData

struct MethodListView: View {
    @Query(sort: [
        SortDescriptor(\BrewMethod.lastUsedDate, order: .reverse),
        SortDescriptor(\BrewMethod.createdAt, order: .reverse)
    ]) private var methods: [BrewMethod]

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false

    var body: some View {
        Group {
            if methods.isEmpty {
                EmptyStateView(
                    systemImage: "cup.and.saucer",
                    title: "No Brew Methods",
                    message: "Add your first brew method to get started",
                    action: { showingAddSheet = true },
                    actionLabel: "Add Method"
                )
            } else {
                List {
                    ForEach(methods) { method in
                        NavigationLink {
                            MethodDetailView(method: method)
                        } label: {
                            EquipmentRow(
                                name: method.name,
                                subtitle: method.category.displayName,
                                iconName: method.category.iconName,
                                photoData: method.photoData,
                                brewCount: method.brewCount,
                                lastUsedDate: method.lastUsedDate
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteMethod(method)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.Equipment.methodList)
            }
        }
        .navigationTitle("Methods")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityIdentifier(AccessibilityID.Equipment.addMethodButton)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                AddMethodView()
            }
        }
    }

    private func deleteMethod(_ method: BrewMethod) {
        modelContext.delete(method)
    }
}
