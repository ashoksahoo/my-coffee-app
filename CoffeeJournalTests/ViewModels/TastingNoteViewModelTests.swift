import Testing
import Foundation
@testable import CoffeeJournal

@Suite("TastingNoteViewModel")
struct TastingNoteViewModelTests {

    // MARK: - toggleFlavor

    @Test("toggleFlavor inserts new flavor ID")
    func toggleFlavorInserts() {
        let vm = TastingNoteViewModel()
        vm.toggleFlavor("fruity.berry")
        #expect(vm.selectedFlavorIds.contains("fruity.berry"))
    }

    @Test("toggleFlavor removes existing flavor ID")
    func toggleFlavorRemoves() {
        let vm = TastingNoteViewModel()
        vm.toggleFlavor("fruity.berry")
        vm.toggleFlavor("fruity.berry")
        #expect(!vm.selectedFlavorIds.contains("fruity.berry"))
    }

    @Test("toggleFlavor adds multiple flavors")
    func toggleFlavorMultiple() {
        let vm = TastingNoteViewModel()
        vm.toggleFlavor("fruity.berry")
        vm.toggleFlavor("sweet.chocolate")
        #expect(vm.selectedFlavorIds.count == 2)
    }

    // MARK: - addCustomTag

    @Test("addCustomTag creates 'custom:' prefixed tag")
    func addCustomTagPrefix() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        #expect(vm.customTags.contains("custom:vanilla"))
    }

    @Test("addCustomTag clears customTagInput")
    func addCustomTagClearsInput() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        #expect(vm.customTagInput.isEmpty)
    }

    @Test("addCustomTag with empty input does nothing")
    func addCustomTagEmptyInput() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = ""
        vm.addCustomTag()
        #expect(vm.customTags.isEmpty)
    }

    @Test("addCustomTag with whitespace-only input does nothing")
    func addCustomTagWhitespaceInput() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "   "
        vm.addCustomTag()
        #expect(vm.customTags.isEmpty)
    }

    @Test("addCustomTag prevents duplicates")
    func addCustomTagPreventsDuplicate() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        #expect(vm.customTags.count == 1)
    }

    @Test("addCustomTag trims whitespace")
    func addCustomTagTrims() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "  vanilla  "
        vm.addCustomTag()
        #expect(vm.customTags.contains("custom:vanilla"))
    }

    // MARK: - removeCustomTag

    @Test("removeCustomTag removes specific tag")
    func removeCustomTag() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        vm.customTagInput = "caramel"
        vm.addCustomTag()
        vm.removeCustomTag("custom:vanilla")
        #expect(!vm.customTags.contains("custom:vanilla"))
        #expect(vm.customTags.contains("custom:caramel"))
    }

    @Test("removeCustomTag with non-existent tag does nothing")
    func removeNonExistentTag() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        vm.removeCustomTag("custom:nonexistent")
        #expect(vm.customTags.count == 1)
    }

    // MARK: - hasChanges

    @Test("hasChanges is false for fresh ViewModel")
    func noChangesOnFreshVM() {
        let vm = TastingNoteViewModel()
        #expect(vm.hasChanges == false)
    }

    @Test("hasChanges is true after setting acidity > 0")
    func changesAfterAcidity() {
        let vm = TastingNoteViewModel()
        vm.acidity = 3
        #expect(vm.hasChanges == true)
    }

    @Test("hasChanges is true after setting bodyRating > 0")
    func changesAfterBody() {
        let vm = TastingNoteViewModel()
        vm.bodyRating = 2
        #expect(vm.hasChanges == true)
    }

    @Test("hasChanges is true after setting sweetness > 0")
    func changesAfterSweetness() {
        let vm = TastingNoteViewModel()
        vm.sweetness = 4
        #expect(vm.hasChanges == true)
    }

    @Test("hasChanges is true after adding flavor")
    func changesAfterFlavor() {
        let vm = TastingNoteViewModel()
        vm.toggleFlavor("fruity.berry")
        #expect(vm.hasChanges == true)
    }

    @Test("hasChanges is true after adding custom tag")
    func changesAfterCustomTag() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        #expect(vm.hasChanges == true)
    }

    @Test("hasChanges is true after setting freeformNotes")
    func changesAfterNotes() {
        let vm = TastingNoteViewModel()
        vm.freeformNotes = "Bright and fruity"
        #expect(vm.hasChanges == true)
    }

    // MARK: - allDisplayTags

    @Test("allDisplayTags with custom tags returns sorted tags")
    func displayTagsSortedCustom() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        vm.customTagInput = "caramel"
        vm.addCustomTag()
        let tags = vm.allDisplayTags
        #expect(tags.count == 2)
        // Should be sorted alphabetically: caramel before vanilla
        #expect(tags[0].name == "caramel")
        #expect(tags[1].name == "vanilla")
    }

    @Test("Custom tag display name strips 'custom:' prefix")
    func customTagDisplayNameStripped() {
        let vm = TastingNoteViewModel()
        vm.customTagInput = "vanilla"
        vm.addCustomTag()
        let tags = vm.allDisplayTags
        #expect(tags.first?.name == "vanilla")
        #expect(tags.first?.id == "custom:vanilla")
    }

    @Test("allDisplayTags is empty for fresh ViewModel")
    func displayTagsEmptyOnFresh() {
        let vm = TastingNoteViewModel()
        #expect(vm.allDisplayTags.isEmpty)
    }
}
