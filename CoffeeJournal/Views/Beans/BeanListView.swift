import SwiftUI
import SwiftData
import VisionKit

// MARK: - Parent View

struct BeanListView: View {
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var showingScanner = false

    var body: some View {
        BeanListContent(searchText: searchText)
            .searchable(text: $searchText, prompt: "Search by roaster or origin")
            .navigationTitle("Beans")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Manually", systemImage: "plus")
                        }

                        if DataScannerViewController.isSupported {
                            Button {
                                showingScanner = true
                            } label: {
                                Label("Scan Bag Label", systemImage: "camera.viewfinder")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppColors.primary)
                    }
                    .accessibilityIdentifier(AccessibilityID.Beans.addButton)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    AddBeanView()
                }
            }
            .sheet(isPresented: $showingScanner) {
                BagScannerSheet()
            }
    }
}

// MARK: - Child View (Dynamic @Query)

struct BeanListContent: View {
    @Query private var beans: [CoffeeBean]
    @Environment(\.modelContext) private var modelContext

    init(searchText: String) {
        if searchText.isEmpty {
            _beans = Query(
                sort: [SortDescriptor(\CoffeeBean.createdAt, order: .reverse)]
            )
        } else {
            let search = searchText
            _beans = Query(
                filter: #Predicate<CoffeeBean> { bean in
                    bean.roaster.localizedStandardContains(search) ||
                    bean.origin.localizedStandardContains(search)
                },
                sort: [SortDescriptor(\CoffeeBean.createdAt, order: .reverse)]
            )
        }
    }

    var body: some View {
        if beans.isEmpty {
            EmptyStateView(
                systemImage: "leaf",
                title: "No Beans Yet",
                message: "Add your first coffee to get started"
            )
        } else {
            List {
                ForEach(beans) { bean in
                    NavigationLink {
                        BeanDetailView(bean: bean)
                    } label: {
                        BeanRow(bean: bean)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(bean)
                        } label: {
                            Label("Delete", systemImage: "trash")
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
                        .tint(AppColors.secondary)
                    }
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.Beans.list)
        }
    }
}
