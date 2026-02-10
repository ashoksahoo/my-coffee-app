import SwiftUI
import SwiftData

// MARK: - Child View (Dynamic @Query with Filtering)

struct BrewHistoryListContent: View {
    @Query private var brews: [BrewLog]
    @Environment(\.modelContext) private var modelContext
    @Binding var exportBrews: [BrewLog]

    let methodID: PersistentIdentifier?
    let beanID: PersistentIdentifier?

    init(searchText: String, methodID: PersistentIdentifier?, beanID: PersistentIdentifier?, startDate: Date?, endDate: Date?, minimumRating: Int, exportBrews: Binding<[BrewLog]> = .constant([])) {
        self._exportBrews = exportBrews
        self.methodID = methodID
        self.beanID = beanID

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
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "No Matches",
                    message: "Try adjusting your filters or search text"
                )
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
            }
        }
        .onAppear { exportBrews = filteredBrews }
        .onChange(of: filteredBrews.count) { exportBrews = filteredBrews }
    }
}
