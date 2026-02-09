// swift-tools-version: 6.0
// This Package.swift enables `swift build` verification when Xcode.app is not installed.
// The canonical project file is CoffeeJournal.xcodeproj for Xcode usage.

import PackageDescription

let package = Package(
    name: "CoffeeJournal",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "CoffeeJournal",
            path: "CoffeeJournal",
            sources: [
                "CoffeeJournalApp.swift",
                "ContentView.swift",
                "Models/MethodCategory.swift",
                "Models/GrinderType.swift",
                "Models/MethodTemplate.swift",
                "Models/BrewMethod.swift",
                "Models/Grinder.swift",
                "Models/CoffeeBean.swift",
                "Models/BrewLog.swift",
                "Models/TastingNote.swift",
                "Models/Schema/SchemaV1.swift",
                "Models/Schema/MigrationPlan.swift",
                "Views/Components/MonochromeStyle.swift",
                "Views/Components/EmptyStateView.swift",
                "Views/Components/EquipmentRow.swift",
                "Utilities/ImageCompressor.swift",
                "Utilities/AppStorageKeys.swift",
                "Utilities/BagLabelParser.swift",
                "Utilities/FreshnessCalculator.swift",
                "Models/RoastLevel.swift",
                "Models/ProcessingMethod.swift",
                "ViewModels/SetupWizardViewModel.swift",
                "ViewModels/BrewLogViewModel.swift",
                "Views/Components/StarRatingView.swift",
                "Views/Brewing/AddBrewLogView.swift",
            ]
        ),
    ]
)
