import Foundation

// MARK: - Flavor Node

struct FlavorNode: Identifiable, Codable, Hashable {
    let id: String      // Dot-path like "fruity.berry.strawberry"
    let name: String
    let children: [FlavorNode]

    var isLeaf: Bool { children.isEmpty }
}

// MARK: - SCA Flavor Wheel (2016 Revision)

struct FlavorWheel {
    static let categories: [FlavorNode] = [
        // 1. Floral
        FlavorNode(id: "floral", name: "Floral", children: [
            FlavorNode(id: "floral.floral", name: "Floral", children: [
                FlavorNode(id: "floral.floral.jasmine", name: "Jasmine", children: []),
                FlavorNode(id: "floral.floral.rose", name: "Rose", children: []),
                FlavorNode(id: "floral.floral.chamomile", name: "Chamomile", children: []),
            ]),
            FlavorNode(id: "floral.tea-like", name: "Tea-like", children: [
                FlavorNode(id: "floral.tea-like.black-tea", name: "Black Tea", children: []),
                FlavorNode(id: "floral.tea-like.green-tea", name: "Green Tea", children: []),
            ]),
        ]),

        // 2. Fruity
        FlavorNode(id: "fruity", name: "Fruity", children: [
            FlavorNode(id: "fruity.berry", name: "Berry", children: [
                FlavorNode(id: "fruity.berry.strawberry", name: "Strawberry", children: []),
                FlavorNode(id: "fruity.berry.raspberry", name: "Raspberry", children: []),
                FlavorNode(id: "fruity.berry.blueberry", name: "Blueberry", children: []),
                FlavorNode(id: "fruity.berry.blackberry", name: "Blackberry", children: []),
            ]),
            FlavorNode(id: "fruity.dried-fruit", name: "Dried Fruit", children: [
                FlavorNode(id: "fruity.dried-fruit.raisin", name: "Raisin", children: []),
                FlavorNode(id: "fruity.dried-fruit.prune", name: "Prune", children: []),
                FlavorNode(id: "fruity.dried-fruit.coconut", name: "Coconut", children: []),
            ]),
            FlavorNode(id: "fruity.citrus", name: "Citrus", children: [
                FlavorNode(id: "fruity.citrus.grapefruit", name: "Grapefruit", children: []),
                FlavorNode(id: "fruity.citrus.orange", name: "Orange", children: []),
                FlavorNode(id: "fruity.citrus.lemon", name: "Lemon", children: []),
                FlavorNode(id: "fruity.citrus.lime", name: "Lime", children: []),
            ]),
            FlavorNode(id: "fruity.other-fruit", name: "Other Fruit", children: [
                FlavorNode(id: "fruity.other-fruit.cherry", name: "Cherry", children: []),
                FlavorNode(id: "fruity.other-fruit.pomegranate", name: "Pomegranate", children: []),
                FlavorNode(id: "fruity.other-fruit.pineapple", name: "Pineapple", children: []),
                FlavorNode(id: "fruity.other-fruit.grape", name: "Grape", children: []),
                FlavorNode(id: "fruity.other-fruit.apple", name: "Apple", children: []),
                FlavorNode(id: "fruity.other-fruit.peach", name: "Peach", children: []),
                FlavorNode(id: "fruity.other-fruit.pear", name: "Pear", children: []),
            ]),
        ]),

        // 3. Sour/Fermented
        FlavorNode(id: "sour-fermented", name: "Sour/Fermented", children: [
            FlavorNode(id: "sour-fermented.sour", name: "Sour", children: [
                FlavorNode(id: "sour-fermented.sour.acetic-acid", name: "Acetic Acid", children: []),
                FlavorNode(id: "sour-fermented.sour.butyric-acid", name: "Butyric Acid", children: []),
                FlavorNode(id: "sour-fermented.sour.citric-acid", name: "Citric Acid", children: []),
                FlavorNode(id: "sour-fermented.sour.malic-acid", name: "Malic Acid", children: []),
            ]),
            FlavorNode(id: "sour-fermented.fermented", name: "Fermented", children: [
                FlavorNode(id: "sour-fermented.fermented.winey", name: "Winey", children: []),
                FlavorNode(id: "sour-fermented.fermented.whiskey", name: "Whiskey", children: []),
                FlavorNode(id: "sour-fermented.fermented.overripe", name: "Overripe", children: []),
            ]),
        ]),

        // 4. Green/Vegetative
        FlavorNode(id: "green-vegetative", name: "Green/Vegetative", children: [
            FlavorNode(id: "green-vegetative.olive-oil", name: "Olive Oil", children: []),
            FlavorNode(id: "green-vegetative.raw", name: "Raw", children: [
                FlavorNode(id: "green-vegetative.raw.under-ripe", name: "Under-ripe", children: []),
                FlavorNode(id: "green-vegetative.raw.peapod", name: "Peapod", children: []),
                FlavorNode(id: "green-vegetative.raw.fresh", name: "Fresh", children: []),
            ]),
            FlavorNode(id: "green-vegetative.vegetative", name: "Vegetative", children: [
                FlavorNode(id: "green-vegetative.vegetative.dark-green", name: "Dark Green", children: []),
                FlavorNode(id: "green-vegetative.vegetative.hay-like", name: "Hay-like", children: []),
                FlavorNode(id: "green-vegetative.vegetative.herb-like", name: "Herb-like", children: []),
            ]),
        ]),

        // 5. Other
        FlavorNode(id: "other", name: "Other", children: [
            FlavorNode(id: "other.papery-musty", name: "Papery/Musty", children: [
                FlavorNode(id: "other.papery-musty.stale", name: "Stale", children: []),
                FlavorNode(id: "other.papery-musty.cardboard", name: "Cardboard", children: []),
                FlavorNode(id: "other.papery-musty.papery", name: "Papery", children: []),
                FlavorNode(id: "other.papery-musty.woody", name: "Woody", children: []),
                FlavorNode(id: "other.papery-musty.musty-dusty", name: "Musty/Dusty", children: []),
                FlavorNode(id: "other.papery-musty.musty-earthy", name: "Musty/Earthy", children: []),
                FlavorNode(id: "other.papery-musty.animalic", name: "Animalic", children: []),
                FlavorNode(id: "other.papery-musty.meaty-brothy", name: "Meaty/Brothy", children: []),
            ]),
            FlavorNode(id: "other.chemical", name: "Chemical", children: [
                FlavorNode(id: "other.chemical.phenolic", name: "Phenolic", children: []),
                FlavorNode(id: "other.chemical.bitter", name: "Bitter", children: []),
                FlavorNode(id: "other.chemical.salty", name: "Salty", children: []),
                FlavorNode(id: "other.chemical.medicinal", name: "Medicinal", children: []),
                FlavorNode(id: "other.chemical.petroleum", name: "Petroleum", children: []),
                FlavorNode(id: "other.chemical.skunky", name: "Skunky", children: []),
                FlavorNode(id: "other.chemical.rubber", name: "Rubber", children: []),
            ]),
        ]),

        // 6. Roasted
        FlavorNode(id: "roasted", name: "Roasted", children: [
            FlavorNode(id: "roasted.pipe-tobacco", name: "Pipe Tobacco", children: []),
            FlavorNode(id: "roasted.cereal", name: "Cereal", children: [
                FlavorNode(id: "roasted.cereal.grain", name: "Grain", children: []),
                FlavorNode(id: "roasted.cereal.malt", name: "Malt", children: []),
            ]),
            FlavorNode(id: "roasted.burnt", name: "Burnt", children: [
                FlavorNode(id: "roasted.burnt.smoky", name: "Smoky", children: []),
                FlavorNode(id: "roasted.burnt.ashy", name: "Ashy", children: []),
                FlavorNode(id: "roasted.burnt.acrid", name: "Acrid", children: []),
                FlavorNode(id: "roasted.burnt.brown-roast", name: "Brown Roast", children: []),
            ]),
        ]),

        // 7. Spices
        FlavorNode(id: "spices", name: "Spices", children: [
            FlavorNode(id: "spices.pungent", name: "Pungent", children: [
                FlavorNode(id: "spices.pungent.pepper", name: "Pepper", children: []),
            ]),
            FlavorNode(id: "spices.brown-spice", name: "Brown Spice", children: [
                FlavorNode(id: "spices.brown-spice.anise", name: "Anise", children: []),
                FlavorNode(id: "spices.brown-spice.nutmeg", name: "Nutmeg", children: []),
                FlavorNode(id: "spices.brown-spice.cinnamon", name: "Cinnamon", children: []),
                FlavorNode(id: "spices.brown-spice.clove", name: "Clove", children: []),
            ]),
        ]),

        // 8. Nutty/Cocoa
        FlavorNode(id: "nutty-cocoa", name: "Nutty/Cocoa", children: [
            FlavorNode(id: "nutty-cocoa.nutty", name: "Nutty", children: [
                FlavorNode(id: "nutty-cocoa.nutty.peanuts", name: "Peanuts", children: []),
                FlavorNode(id: "nutty-cocoa.nutty.hazelnut", name: "Hazelnut", children: []),
                FlavorNode(id: "nutty-cocoa.nutty.almond", name: "Almond", children: []),
            ]),
            FlavorNode(id: "nutty-cocoa.cocoa", name: "Cocoa", children: [
                FlavorNode(id: "nutty-cocoa.cocoa.dark-chocolate", name: "Dark Chocolate", children: []),
                FlavorNode(id: "nutty-cocoa.cocoa.chocolate", name: "Chocolate", children: []),
            ]),
        ]),

        // 9. Sweet
        FlavorNode(id: "sweet", name: "Sweet", children: [
            FlavorNode(id: "sweet.brown-sugar", name: "Brown Sugar", children: [
                FlavorNode(id: "sweet.brown-sugar.molasses", name: "Molasses", children: []),
                FlavorNode(id: "sweet.brown-sugar.maple-syrup", name: "Maple Syrup", children: []),
                FlavorNode(id: "sweet.brown-sugar.brown-sugar", name: "Brown Sugar", children: []),
                FlavorNode(id: "sweet.brown-sugar.honey", name: "Honey", children: []),
                FlavorNode(id: "sweet.brown-sugar.caramelized", name: "Caramelized", children: []),
            ]),
            FlavorNode(id: "sweet.vanilla", name: "Vanilla", children: [
                FlavorNode(id: "sweet.vanilla.vanilla", name: "Vanilla", children: []),
                FlavorNode(id: "sweet.vanilla.vanillin", name: "Vanillin", children: []),
            ]),
            FlavorNode(id: "sweet.overall-sweet", name: "Overall Sweet", children: [
                FlavorNode(id: "sweet.overall-sweet.sweet-aromatics", name: "Sweet Aromatics", children: []),
            ]),
        ]),
    ]

    // MARK: - Queries

    /// Recursively collects all leaf nodes from the flavor wheel hierarchy.
    static func flatDescriptors() -> [FlavorNode] {
        func collectLeaves(_ nodes: [FlavorNode]) -> [FlavorNode] {
            var leaves: [FlavorNode] = []
            for node in nodes {
                if node.isLeaf {
                    leaves.append(node)
                } else {
                    leaves.append(contentsOf: collectLeaves(node.children))
                }
            }
            return leaves
        }
        return collectLeaves(categories)
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
