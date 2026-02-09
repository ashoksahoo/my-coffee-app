import SwiftUI
import SwiftData

struct GrinderListView: View {
    @Query(sort: [
        SortDescriptor(\Grinder.lastUsedDate, order: .reverse),
        SortDescriptor(\Grinder.createdAt, order: .reverse)
    ]) private var grinders: [Grinder]

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false

    var body: some View {
        Group {
            if grinders.isEmpty {
                EmptyStateView(
                    systemImage: "gearshape",
                    title: "No Grinders",
                    message: "Add your first grinder to get started",
                    action: { showingAddSheet = true },
                    actionLabel: "Add Grinder"
                )
            } else {
                List {
                    ForEach(grinders) { grinder in
                        NavigationLink {
                            GrinderDetailView(grinder: grinder)
                        } label: {
                            EquipmentRow(
                                name: grinder.name,
                                subtitle: grinder.grinderType.displayName,
                                iconName: grinder.grinderType.iconName,
                                photoData: grinder.photoData,
                                brewCount: grinder.brewCount,
                                lastUsedDate: grinder.lastUsedDate
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteGrinder(grinder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Grinders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                AddGrinderView()
            }
        }
    }

    private func deleteGrinder(_ grinder: Grinder) {
        modelContext.delete(grinder)
    }
}
