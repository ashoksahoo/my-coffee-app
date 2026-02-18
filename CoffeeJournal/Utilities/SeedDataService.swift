#if DEBUG
import Foundation
import SwiftData

/// Seeds realistic sample data for testing the Foundation Models insights feature.
/// Creates beans, brew methods, a grinder, and 30+ brew logs with rich tasting notes.
enum SeedDataService {

    static func seed(into context: ModelContext) {
        // Avoid double-seeding
        let descriptor = FetchDescriptor<BrewLog>()
        let existing = (try? context.fetch(descriptor))?.count ?? 0
        guard existing == 0 else { return }

        let methods = makeBrewMethods()
        let grinder = makeGrinder()
        let beans = makeBeans()

        for item in methods { context.insert(item) }
        context.insert(grinder)
        for bean in beans { context.insert(bean) }

        let logs = makeBrewLogs(beans: beans, methods: methods, grinder: grinder)
        for (log, note) in logs {
            context.insert(log)
            context.insert(note)
        }
    }

    // MARK: - Brew Methods

    private static func makeBrewMethods() -> [BrewMethod] {
        [
            BrewMethod(name: "V60 Pour Over", category: .pourOver),
            BrewMethod(name: "Espresso",      category: .espresso),
            BrewMethod(name: "French Press",  category: .immersion),
        ]
    }

    // MARK: - Grinder

    private static func makeGrinder() -> Grinder {
        let g = Grinder(name: "Comandante C40", type: .burr)
        g.notes = "Hand grinder, 40-click range"
        return g
    }

    // MARK: - Coffee Beans

    private static func makeBeans() -> [CoffeeBean] {
        let calendar = Calendar.current
        func roastDate(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        }

        let data: [(name: String, roaster: String, origin: String, region: String,
                     variety: String, processing: ProcessingMethod, roast: RoastLevel, daysAgo: Int)] = [
            ("Yirgacheffe Natural", "Onyx Coffee Lab",
             "Ethiopia", "Yirgacheffe", "Heirloom", .natural, .light, 14),
            ("El Paraíso Washed", "Intelligentsia",
             "Colombia", "Huila", "Caturra", .washed, .light, 10),
            ("Nyeri AA", "Square Mile",
             "Kenya", "Nyeri", "SL28", .washed, .mediumLight, 18),
            ("Antigua Honey", "Verve",
             "Guatemala", "Antigua", "Bourbon", .honey, .medium, 21),
            ("Yellow Bourbon Natural", "Counter Culture",
             "Brazil", "Cerrado", "Yellow Bourbon", .natural, .medium, 25),
        ]

        return data.map { d in
            let b = CoffeeBean()
            b.name = d.name
            b.roaster = d.roaster
            b.origin = d.origin
            b.region = d.region
            b.variety = d.variety
            b.processingMethod = d.processing.rawValue
            b.roastLevel = d.roast.rawValue
            b.roastDate = roastDate(daysAgo: d.daysAgo)
            return b
        }
    }

    // MARK: - Brew Logs

    private static func makeBrewLogs(
        beans: [CoffeeBean],
        methods: [BrewMethod],
        grinder: Grinder
    ) -> [(BrewLog, TastingNote)] {

        let pourOver  = methods[0]
        let espresso  = methods[1]
        let french    = methods[2]

        let ethiopia  = beans[0]
        let colombia  = beans[1]
        let kenya     = beans[2]
        let guatemala = beans[3]
        let brazil    = beans[4]

        let entries: [(bean: CoffeeBean, method: BrewMethod, daysAgo: Int,
                        dose: Double, water: Double, brewTime: Double, temp: Double,
                        yield: Double, grind: Double, rating: Int, notes: String,
                        acidity: Int, body: Int, sweetness: Int, flavors: String)] = [

            // Ethiopia – V60 (7 brews, 3-4 stars)
            (ethiopia, pourOver, 2,  18, 300, 210, 92, 0, 22, 5,
             "Bright blueberry and jasmine on the nose. Very juicy with a wine-like fermented quality.",
             4, 2, 4, "blueberry,jasmine,floral,winey,fermented"),
            (ethiopia, pourOver, 5,  18, 300, 205, 92, 0, 22, 5,
             "Intense strawberry jam sweetness, lemon zest acidity, delicate rose petal finish.",
             5, 2, 5, "strawberry,lemon,rose,floral,citrus"),
            (ethiopia, pourOver, 8,  17, 285, 215, 91, 0, 21, 4,
             "Stone fruit, peach and apricot, with a delicate floral top note and pleasant tartness.",
             4, 2, 4, "peach,apricot,floral,tart,stone fruit"),
            (ethiopia, pourOver, 11, 18, 300, 210, 92, 0, 23, 5,
             "Complex tropical notes — mango, papaya — with a hibiscus-like acidity.",
             4, 2, 5, "mango,tropical,hibiscus,fruity,floral"),
            (ethiopia, pourOver, 14, 18, 295, 208, 92, 0, 22, 4,
             "Blueberry muffin sweetness, lime acidity, clean finish.",
             4, 2, 4, "blueberry,lime,sweet,clean,citrus"),
            (ethiopia, pourOver, 17, 17, 280, 212, 91, 0, 21, 3,
             "Slightly muted today — still fruity but less vibrant. Mild grape and cranberry.",
             3, 2, 3, "grape,cranberry,fruity"),
            (ethiopia, pourOver, 20, 18, 300, 207, 92, 0, 22, 5,
             "Best shot yet. Bright and complex: blood orange, raspberry, earl grey tea finish.",
             5, 2, 5, "blood orange,raspberry,tea,floral,citrus"),

            // Colombia – V60 (6 brews)
            (colombia, pourOver, 3,  18, 300, 215, 93, 0, 18, 4,
             "Milk chocolate and caramel sweetness, mild apple acidity, nutty finish.",
             3, 3, 4, "chocolate,caramel,apple,nutty,sweet"),
            (colombia, pourOver, 6,  18, 300, 210, 93, 0, 18, 5,
             "Red apple, praline, and a lingering hazelnut aftertaste. Very well-balanced.",
             3, 3, 5, "apple,praline,hazelnut,nutty,sweet"),
            (colombia, pourOver, 9,  17, 285, 213, 93, 0, 17, 4,
             "Brown sugar, toffee, mild citrus brightness. Creamy body.",
             3, 3, 4, "brown sugar,toffee,citrus,creamy,sweet"),
            (colombia, pourOver, 12, 18, 300, 212, 93, 0, 18, 5,
             "Exceptional: nougat, golden raisin, light jasmine and a cocoa powder finish.",
             3, 3, 5, "nougat,raisin,jasmine,cocoa,floral"),
            (colombia, pourOver, 15, 18, 295, 216, 92, 0, 18, 3,
             "A bit over-extracted. Bitter chocolate, drying finish.",
             2, 3, 2, "chocolate,bitter,dry"),
            (colombia, pourOver, 18, 18, 300, 211, 93, 0, 18, 4,
             "Balanced and pleasant: caramel apple, mild almond, clean sweet finish.",
             3, 3, 4, "caramel,apple,almond,sweet,clean"),

            // Kenya – V60 (5 brews)
            (kenya, pourOver, 4,  18, 300, 205, 94, 0, 24, 5,
             "Tomato, blackcurrant, intense savory-sweet contrast. Incredibly complex.",
             5, 3, 4, "blackcurrant,tomato,savory,complex,fruity"),
            (kenya, pourOver, 7,  18, 300, 207, 94, 0, 24, 5,
             "Blackberry jam, dark cherry, juicy acidity. Like biting into a ripe plum.",
             5, 3, 4, "blackberry,cherry,plum,fruity,juicy"),
            (kenya, pourOver, 10, 17, 285, 210, 93, 0, 23, 4,
             "Bright grapefruit acidity, red grape sweetness, tea-like finish.",
             5, 2, 4, "grapefruit,grape,tea,citrus,fruity"),
            (kenya, pourOver, 13, 18, 295, 208, 94, 0, 24, 4,
             "Dried cranberry and hibiscus, syrupy body, lingering currant notes.",
             5, 3, 4, "cranberry,hibiscus,currant,syrupy,fruity"),
            (kenya, pourOver, 16, 18, 300, 206, 94, 0, 24, 5,
             "Top of its game: lime zest, blood orange, subtle savory umami background.",
             5, 3, 3, "lime,blood orange,citrus,savory,umami"),

            // Guatemala – Espresso (5 brews)
            (guatemala, espresso, 1,  18, 0, 28, 94, 38, 14, 5,
             "Silky espresso with brown sugar sweetness, dark chocolate, dried fig. Long finish.",
             3, 5, 5, "brown sugar,dark chocolate,fig,sweet,creamy"),
            (guatemala, espresso, 4,  18, 0, 27, 94, 36, 14, 5,
             "Dense caramel crema. Dark cherry, bittersweet cocoa, molasses undertone.",
             3, 5, 4, "caramel,cherry,cocoa,molasses,bittersweet"),
            (guatemala, espresso, 7,  18, 0, 29, 94, 38, 14, 4,
             "Dried fruit sweetness, walnut bitterness, smooth and balanced.",
             3, 4, 4, "dried fruit,walnut,bitter,smooth,balanced"),
            (guatemala, espresso, 10, 18, 0, 27, 94, 36, 14, 4,
             "Roasted hazelnut, soft stone fruit, pleasant bitterness.",
             2, 4, 3, "hazelnut,stone fruit,roasted,bitter"),
            (guatemala, espresso, 13, 18, 0, 28, 94, 37, 14, 5,
             "Intense dark chocolate espresso, notes of brandy and stewed plum.",
             3, 5, 4, "dark chocolate,brandy,plum,roasted,sweet"),

            // Brazil – French Press (5 brews)
            (brazil, french, 3,  20, 320, 240, 93, 0, 16, 4,
             "Rich, heavy body. Dark chocolate, roasted peanut, earthy sweetness. Comforting.",
             2, 5, 3, "dark chocolate,peanut,earthy,roasted,sweet"),
            (brazil, french, 6,  20, 320, 245, 93, 0, 16, 4,
             "Nutty and smooth. Almond milk, mild chocolate, brown sugar. Very drinkable.",
             2, 5, 4, "almond,chocolate,brown sugar,smooth,nutty"),
            (brazil, french, 9,  20, 320, 242, 93, 0, 16, 3,
             "Slightly muddy. Chocolate and peanut butter notes, a bit heavy.",
             2, 5, 2, "chocolate,peanut butter,heavy,nutty"),
            (brazil, french, 12, 20, 320, 240, 93, 0, 16, 5,
             "Best French Press in a while. Velvety body, cocoa nibs, vanilla sweetness, caramel.",
             2, 5, 5, "cocoa,vanilla,caramel,smooth,sweet"),
            (brazil, french, 15, 20, 315, 238, 93, 0, 15, 4,
             "Full-bodied and cozy. Toasted hazelnuts, milk chocolate, subtle maple sweetness.",
             2, 5, 4, "hazelnut,milk chocolate,maple,sweet,nutty"),

            // Colombia – Espresso (4 brews for cross-method coverage)
            (colombia, espresso, 2,  18, 0, 26, 93, 36, 13, 5,
             "Bright and sweet: red apple, caramel, almond. Balanced espresso profile.",
             3, 4, 5, "apple,caramel,almond,sweet,bright"),
            (colombia, espresso, 5,  18, 0, 27, 93, 36, 13, 4,
             "Syrupy texture, brown sugar, mild dark fruit sweetness.",
             3, 4, 4, "brown sugar,dark fruit,syrupy,sweet"),
            (colombia, espresso, 8,  18, 0, 27, 93, 37, 13, 4,
             "Hazelnut praline and orange blossom. Smooth, sweet finish.",
             3, 4, 4, "hazelnut,orange,floral,smooth,sweet"),
            (colombia, espresso, 11, 18, 0, 26, 93, 35, 13, 5,
             "Outstanding: nougat, candied orange, lingering cocoa aftertaste.",
             3, 4, 5, "nougat,orange,cocoa,sweet,floral"),
        ]

        let calendar = Calendar.current
        return entries.map { e in
            let log = BrewLog()
            log.coffeeBean      = e.bean
            log.brewMethod      = e.method
            log.grinder         = grinder
            log.dose            = e.dose
            log.waterAmount     = e.water
            log.brewTime        = e.brewTime
            log.waterTemperature = e.temp
            log.yieldAmount     = e.yield
            log.grinderSetting  = e.grind
            log.rating          = e.rating
            log.notes           = e.notes
            log.createdAt       = calendar.date(byAdding: .day, value: -e.daysAgo, to: Date()) ?? Date()
            log.updatedAt       = log.createdAt

            e.method.brewCount += 1
            if e.method.lastUsedDate == nil || log.createdAt > e.method.lastUsedDate! {
                e.method.lastUsedDate = log.createdAt
            }

            let note = TastingNote()
            note.acidity    = e.acidity
            note.body       = e.body
            note.sweetness  = e.sweetness
            note.flavorTags = e.flavors
            note.freeformNotes = e.notes
            note.brewLog    = log
            note.createdAt  = log.createdAt
            note.updatedAt  = log.createdAt

            return (log, note)
        }
    }
}
#endif
