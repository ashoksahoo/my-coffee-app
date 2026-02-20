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
        minimumRating > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            searchAndFilterBar

            BrewHistoryListContent(
                searchText: searchText,
                methodID: selectedMethodID,
                beanID: selectedBeanID,
                startDate: startDate,
                endDate: endDate,
                minimumRating: minimumRating,
                hasActiveFilters: hasActiveFilters || !searchText.isEmpty,
                onAddBrew: { showingAddSheet = true }
            )
        }
        .navigationTitle("Brews")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.primary)
                }
                .accessibilityIdentifier(AccessibilityID.Brews.addButton)
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

    // MARK: - Search + Filter Bar

    private var searchAndFilterBar: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.muted)
                TextField("Search brew notes", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.Brews.searchField)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.muted)
                    }
                }
            }
            .padding(AppSpacing.sm)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                showingFilterSheet = true
            } label: {
                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
