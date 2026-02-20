import Foundation

// MARK: - Flavor Node

struct FlavorNode: Identifiable, Codable, Hashable {
    let id: String      // Dot-path like "fruity.berry.strawberry"
    let name: String
    let children: [FlavorNode]

    var isLeaf: Bool { children.isEmpty }
}

// MARK: - Flavor Wheel Loader
//
// Data source priority (highest to lowest):
//   1. <App Documents>/FlavorWheel.json  — drop a file here to override without rebuilding
//   2. FlavorWheel.json in the app bundle — the default shipped with the app
//
// To customise the wheel:
//   • Edit CoffeeJournal/Resources/FlavorWheel.json and rebuild, OR
//   • Copy a modified FlavorWheel.json into the app's Documents directory
//     (via Xcode Devices window, Files app, or the simulator's sandbox) and call
//     FlavorWheel.reload() — changes are picked up immediately without a rebuild.

struct FlavorWheel {

    // Cached after first load; call reload() to force a re-read from disk.
    private static var _categories: [FlavorNode]?

    static var categories: [FlavorNode] {
        if let cached = _categories { return cached }
        let loaded = loadCategories()
        _categories = loaded
        return loaded
    }

    /// Clears the cache so the next access re-reads from disk.
    /// Call this after dropping a new FlavorWheel.json into Documents at runtime.
    static func reload() {
        _categories = nil
    }

    // MARK: - Loading

    private static func loadCategories() -> [FlavorNode] {
        // 1. Documents override (hot-swap without rebuild)
        if let url  = documentsURL,
           FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let cats = try? JSONDecoder().decode([FlavorNode].self, from: data) {
            return cats
        }

        // 2. Bundled default
        if let url  = Bundle.main.url(forResource: "FlavorWheel", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let cats = try? JSONDecoder().decode([FlavorNode].self, from: data) {
            return cats
        }

        // 3. Should never reach here — bundle file is always present
        assertionFailure("FlavorWheel.json not found in app bundle")
        return []
    }

    /// URL for an optional user-supplied override in the app's Documents directory.
    static var documentsURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("FlavorWheel.json")
    }

    // MARK: - Queries

    /// All leaf nodes (selectable flavor descriptors).
    static func flatDescriptors() -> [FlavorNode] {
        func leaves(_ nodes: [FlavorNode]) -> [FlavorNode] {
            nodes.flatMap { $0.isLeaf ? [$0] : leaves($0.children) }
        }
        return leaves(categories)
    }

    /// Finds a node by its dot-path id anywhere in the hierarchy.
    static func findNode(byId id: String) -> FlavorNode? {
        func search(_ nodes: [FlavorNode]) -> FlavorNode? {
            for node in nodes {
                if node.id == id { return node }
                if let found = search(node.children) { return found }
            }
            return nil
        }
        return search(categories)
    }
}
