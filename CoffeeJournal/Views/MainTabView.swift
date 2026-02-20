import SwiftUI

// MARK: - Sidebar Items

enum SidebarItem: String, CaseIterable, Identifiable {
    case methods
    case grinders
    case statistics
    case compare
    case export
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .methods: "Methods"
        case .grinders: "Grinders"
        case .statistics: "Statistics"
        case .compare: "Compare Brews"
        case .export: "Export"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .methods: "cup.and.saucer"
        case .grinders: "gearshape.2"
        case .statistics: "chart.bar.xaxis"
        case .compare: "arrow.left.arrow.right"
        case .export: "square.and.arrow.up"
        case .settings: "gearshape"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .methods: MethodListView()
        case .grinders: GrinderListView()
        case .statistics: StatisticsDashboardView()
        case .compare: BrewComparisonView()
        case .export: ExportView()
        case .settings: SettingsView()
        }
    }
}

// MARK: - Main View

struct MainTabView: View {
    @State private var isSidebarOpen = false
    @State private var presentedItem: SidebarItem?

    var body: some View {
        ZStack(alignment: .leading) {
            tabContent
                .disabled(isSidebarOpen)

            if isSidebarOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { closeSidebar() }
                    .zIndex(1)
            }

            sidebarPanel
                .zIndex(2)
        }
        .animation(.easeOut(duration: 0.25), value: isSidebarOpen)
        .fullScreenCover(item: $presentedItem) { item in
            NavigationStack {
                item.destination
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { presentedItem = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        TabView {
            NavigationStack {
                BrewLogListView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            sidebarToggle
                        }
                    }
            }
            .tabItem { Label("Brews", systemImage: "mug") }
            .accessibilityIdentifier(AccessibilityID.Sidebar.brews)

            NavigationStack {
                BeanListView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            sidebarToggle
                        }
                    }
            }
            .tabItem { Label("Beans", systemImage: "leaf") }
            .accessibilityIdentifier(AccessibilityID.Sidebar.beans)
        }
        .tint(Color.primary)
    }

    // MARK: - Sidebar Toggle

    private var sidebarToggle: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) {
                isSidebarOpen.toggle()
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(AppColors.primary)
        }
    }

    // MARK: - Sidebar Panel

    private var sidebarPanel: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Coffee Journal")
                    .font(.title2.bold())
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .padding(.bottom, 16)

                List {
                    Section("Equipment") {
                        sidebarRow(.methods)
                        sidebarRow(.grinders)
                    }
                    Section("Analysis") {
                        sidebarRow(.statistics)
                        sidebarRow(.compare)
                    }
                    Section {
                        sidebarRow(.export)
                        sidebarRow(.settings)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(width: 280)
            .background(.regularMaterial)

            Spacer(minLength: 0)
        }
        .offset(x: isSidebarOpen ? 0 : -280)
    }

    private func sidebarRow(_ item: SidebarItem) -> some View {
        Button {
            closeSidebar()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                presentedItem = item
            }
        } label: {
            Label(item.label, systemImage: item.systemImage)
        }
        .accessibilityIdentifier(AccessibilityID.Sidebar.id(for: item.rawValue))
    }

    private func closeSidebar() {
        withAnimation(.easeOut(duration: 0.25)) {
            isSidebarOpen = false
        }
    }
}

#Preview {
    MainTabView()
}
