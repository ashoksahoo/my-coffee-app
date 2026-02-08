import Foundation

struct MethodTemplate: Hashable, Identifiable {
    let name: String
    let category: MethodCategory
    let iconName: String

    var id: String { name }

    static let curatedMethods: [MethodTemplate] = [
        MethodTemplate(name: "V60", category: .pourOver, iconName: "cup.and.saucer"),
        MethodTemplate(name: "AeroPress", category: .immersion, iconName: "arrow.down.circle"),
        MethodTemplate(name: "Espresso", category: .espresso, iconName: "cup.and.saucer.fill"),
        MethodTemplate(name: "French Press", category: .immersion, iconName: "mug"),
        MethodTemplate(name: "Chemex", category: .pourOver, iconName: "flask"),
        MethodTemplate(name: "Moka Pot", category: .other, iconName: "flame"),
        MethodTemplate(name: "Kalita Wave", category: .pourOver, iconName: "drop.circle"),
        MethodTemplate(name: "Clever Dripper", category: .immersion, iconName: "cup.and.saucer"),
        MethodTemplate(name: "Hario Switch", category: .immersion, iconName: "switch.2"),
        MethodTemplate(name: "Turkish", category: .other, iconName: "cup.and.saucer"),
    ]
}
