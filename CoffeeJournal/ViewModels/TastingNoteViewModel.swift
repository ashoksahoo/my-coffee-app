import Foundation
import SwiftData
import Observation

@Observable
final class TastingNoteViewModel {
    var acidity: Int = 0        // 0 = not rated, 1-5 = rated
    var bodyRating: Int = 0     // Named bodyRating to avoid conflict with SwiftUI View.body
    var sweetness: Int = 0
    var selectedFlavorIds: Set<String> = []  // FlavorNode dot-path IDs
    var customTags: [String] = []            // User-added tags (stored with "custom:" prefix)
    var customTagInput: String = ""          // Text field binding for adding custom tag
    var freeformNotes: String = ""

    // MARK: - Flavor Management

    func toggleFlavor(_ id: String) {
        if selectedFlavorIds.contains(id) {
            selectedFlavorIds.remove(id)
        } else {
            selectedFlavorIds.insert(id)
        }
    }

    func addCustomTag() {
        let trimmed = customTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let tag = "custom:\(trimmed)"
        guard !customTags.contains(tag) else { return }
        customTags.append(tag)
        customTagInput = ""
    }

    func removeCustomTag(_ tag: String) {
        customTags.removeAll { $0 == tag }
    }

    // MARK: - Load from Existing Note

    func loadFromTastingNote(_ note: TastingNote) {
        acidity = note.acidity
        bodyRating = note.body
        sweetness = note.sweetness
        freeformNotes = note.freeformNotes

        // Decode flavorTags JSON string
        guard !note.flavorTags.isEmpty,
              let data = note.flavorTags.data(using: .utf8),
              let tags = try? JSONDecoder().decode([String].self, from: data) else {
            return
        }

        selectedFlavorIds = []
        customTags = []

        for tag in tags {
            if tag.hasPrefix("custom:") {
                customTags.append(tag)
            } else {
                selectedFlavorIds.insert(tag)
            }
        }
    }

    // MARK: - Save

    func save(for brewLog: BrewLog, in context: ModelContext) {
        let note: TastingNote
        if let existing = brewLog.tastingNote {
            note = existing
        } else {
            note = TastingNote()
            context.insert(note)
            note.brewLog = brewLog
        }

        note.acidity = acidity
        note.body = bodyRating
        note.sweetness = sweetness
        note.freeformNotes = freeformNotes
        note.updatedAt = Date()

        // Encode flavor tags as JSON string
        let allTags = Array(selectedFlavorIds.sorted()) + customTags.sorted()
        if let data = try? JSONEncoder().encode(allTags),
           let json = String(data: data, encoding: .utf8) {
            note.flavorTags = json
        }
    }

    // MARK: - Computed Properties

    /// Returns selected flavors (looked up by name from FlavorWheel) plus custom tags,
    /// sorted alphabetically by display name.
    var allDisplayTags: [(id: String, name: String)] {
        var tags: [(id: String, name: String)] = []

        for flavorId in selectedFlavorIds {
            if let node = FlavorWheel.findNode(byId: flavorId) {
                tags.append((id: flavorId, name: node.name))
            }
        }

        for tag in customTags {
            let displayName = String(tag.dropFirst("custom:".count))
            tags.append((id: tag, name: displayName))
        }

        return tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// True if any field is non-default.
    var hasChanges: Bool {
        acidity != 0 ||
        bodyRating != 0 ||
        sweetness != 0 ||
        !selectedFlavorIds.isEmpty ||
        !customTags.isEmpty ||
        !freeformNotes.isEmpty
    }
}
