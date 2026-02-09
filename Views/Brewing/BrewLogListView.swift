import SwiftUI
import SwiftData

// MARK: - Parent View

struct BrewLogListView: View {
    @State private var searchText: String = ""
    @State private var selectedMethodID: PersistentIdentifier? = nil
    @State private var selectedBeanID: PersistentIdentifier? = nil
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var minimumRating: Int = 0
    @State private var showingFilterSheet = false
    @State private var showingAddSheet = false

    private var hasActiveFilters: Bool {
        selectedMethodID != nil ||
        selectedBeanID != nil ||
        startDate != nil ||
        endDate != nil ||
        minimumRating > 0 ||
        !searchText.isEmpty
    }

    var body: some View {
        BrewHistoryListContent(
            searchText: searchText,
            methodID: selectedMethodID,
            beanID: selectedBeanID,
            startDate: startDate,
            endDate: endDate,
            minimumRating: minimumRating
        )
        .searchable(text: $searchText, prompt: "Search brew notes")
        .navigationTitle("Brews")
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                NavigationLink {
                    BrewComparisonView()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(AppColors.primary)
                }
                NavigationLink {
                    StatisticsDashboardView()
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundStyle(AppColors.primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(AppColors.primary)
                }
            }
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
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                BrewFilterSheet(
                    selectedMethodID: $selectedMethodID,
                    selectedBeanID: $selectedBeanID,
                    startDate: $startDate,
                    endDate: $endDate,
                    minimumRating: $minimumRating
                )
            }
        }
    }
}
