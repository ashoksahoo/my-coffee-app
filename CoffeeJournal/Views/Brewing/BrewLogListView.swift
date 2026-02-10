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

    // Export state
    @State private var exportBrews: [BrewLog] = []
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var exportType: String = ""
    @State private var showShareSheet = false

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
            minimumRating: minimumRating,
            exportBrews: $exportBrews
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
                Menu {
                    Button {
                        exportPDF()
                    } label: {
                        Label("Export PDF", systemImage: "doc.richtext")
                    }
                    .disabled(exportBrews.isEmpty || isExporting)

                    Button {
                        exportCSV()
                    } label: {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                    .disabled(exportBrews.isEmpty || isExporting)
                } label: {
                    Image(systemName: "square.and.arrow.up")
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
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                if exportType == "pdf" {
                    ShareLink(item: ExportedPDF(url: url), preview: SharePreview("Coffee Journal", image: Image(systemName: "doc.richtext")))
                } else {
                    ShareLink(item: ExportedCSV(url: url), preview: SharePreview("Coffee Journal", image: Image(systemName: "tablecells")))
                }
            }
        }
    }

    // MARK: - Export Functions

    private func exportPDF() {
        isExporting = true
        Task { @MainActor in
            exportURL = PDFExporter.generateJournal(brews: exportBrews)
            isExporting = false
            if exportURL != nil {
                exportType = "pdf"
                showShareSheet = true
            }
        }
    }

    private func exportCSV() {
        isExporting = true
        Task { @MainActor in
            exportURL = CSVExporter.generateCSV(brews: exportBrews)
            isExporting = false
            if exportURL != nil {
                exportType = "csv"
                showShareSheet = true
            }
        }
    }
}
