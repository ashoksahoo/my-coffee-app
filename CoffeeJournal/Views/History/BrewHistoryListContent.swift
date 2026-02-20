import SwiftUI
import SwiftData

// MARK: - Child View (Dynamic @Query with Filtering)

struct BrewHistoryListContent: View {
    @Query private var brews: [BrewLog]
    @Environment(\.modelContext) private var modelContext

    let methodID: PersistentIdentifier?
    let beanID: PersistentIdentifier?
    let hasActiveFilters: Bool
    var onAddBrew: (() -> Void)?

    init(searchText: String, methodID: PersistentIdentifier?, beanID: PersistentIdentifier?, startDate: Date?, endDate: Date?, minimumRating: Int, hasActiveFilters: Bool = false, onAddBrew: (() -> Void)? = nil) {
        self.methodID = methodID
        self.beanID = beanID
        self.hasActiveFilters = hasActiveFilters
        self.onAddBrew = onAddBrew

        let search = searchText
        let minRating = minimumRating
        let sDate = startDate
        let eDate = endDate

        _brews = Query(
            filter: #Predicate<BrewLog> { brew in
                (search.isEmpty || brew.notes.localizedStandardContains(search)) &&
                brew.rating >= minRating &&
                (sDate == nil || brew.createdAt >= sDate!) &&
                (eDate == nil || brew.createdAt <= eDate!)
            },
            sort: [SortDescriptor(\BrewLog.createdAt, order: .reverse)]
        )
    }

    private var filteredBrews: [BrewLog] {
        var result = Array(brews)

        if let mID = methodID {
            result = result.filter { $0.brewMethod?.persistentModelID == mID }
        }

        if let bID = beanID {
            result = result.filter { $0.coffeeBean?.persistentModelID == bID }
        }

        return result
    }

    var body: some View {
        Group {
            if filteredBrews.isEmpty {
                if hasActiveFilters {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No Matches",
                        message: "Try adjusting your filters or search text"
                    )
                } else {
                    EmptyStateView(
                        systemImage: "cup.and.saucer",
                        title: "Your First Cup Awaits",
                        message: "Start tracking your coffee journey — log a brew and discover what makes your perfect cup.",
                        action: onAddBrew,
                        actionLabel: "Log a Brew"
                    )
                }
            } else {
                List {
                    ForEach(filteredBrews) { brew in
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
                .accessibilityIdentifier(AccessibilityID.Brews.list)
            }
        }
    }
}
