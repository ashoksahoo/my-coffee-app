import SwiftUI
import SwiftData

// MARK: - Parent View

struct BrewLogListView: View {
    @State private var showingAddSheet = false

    var body: some View {
        BrewLogListContent()
            .navigationTitle("Brews")
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
                    AddBrewLogView()
                }
            }
    }
}

// MARK: - Child View (Dynamic @Query)

struct BrewLogListContent: View {
    @Query(sort: \BrewLog.createdAt, order: .reverse) private var brews: [BrewLog]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if brews.isEmpty {
            EmptyStateView(
                systemImage: "cup.and.saucer",
                title: "No Brews Yet",
                message: "Log your first brew to start tracking"
            )
        } else {
            List {
                ForEach(brews) { brew in
                    NavigationLink {
                        BrewLogDetailView(brew: brew)
                    } label: {
                        BrewLogRow(brew: brew)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(brew)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
