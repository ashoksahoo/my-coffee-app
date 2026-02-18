# Coffee Journal — UX Information Architecture

**App:** Coffee Journal
**Platform:** iOS
**Date:** 2026-02-18

---

## 1. Overview

Coffee Journal is a personal brew tracking app for coffee enthusiasts. Users log brews, manage bean inventory and equipment, capture tasting notes, and gain insights from their brewing history.

---

## 2. App Entry & Routing

```
App Launch
└── ContentView
    ├── [First Launch] → SetupWizardView (full-screen onboarding)
    └── [Returning User] → MainTabView
```

---

## 3. Onboarding — Setup Wizard

A linear 4-step wizard shown once on first launch. Progress is tracked via a top progress bar. Users can skip optional steps.

| Step | Screen | Required | Content |
|------|--------|----------|---------|
| 1 | WelcomeStepView | No | App introduction, "Get Started" CTA |
| 2 | MethodSelectionView | Yes | Select preset brew methods (Espresso, Pour Over, AeroPress, etc.) |
| 3 | GrinderEntryView | No | Enter grinder name and type (Burr / Blade / Other) |
| 4 | SetupCompleteView | — | Summary of selected methods and grinder, confirmation |

**Completion:** Saves equipment to database, sets `hasCompletedSetup` flag in AppStorage.

---

## 4. Main Navigation Structure

```
MainTabView
├── Tab 1: Brews (BrewLogListView)
├── Tab 2: Beans (BeanListView)
└── Sidebar (Hamburger Menu, 280pt)
    ├── Equipment
    │   ├── Methods
    │   └── Grinders
    ├── Analysis
    │   ├── Statistics
    │   └── Compare Brews
    └── Other
        ├── Export
        └── Settings
```

---

## 5. Screen Inventory

### 5.1 Tab 1 — Brews

| Screen | Access | Type | Purpose |
|--------|--------|------|---------|
| BrewLogListView | Tab bar | Root | Searchable list of all brews with filter |
| BrewFilterSheet | Filter button | Sheet | Filter by method, bean, date range, rating |
| AddBrewLogView | "+" button | Sheet | Log a new brew session |
| BrewTimerView | Inside AddBrewLogView | Inline | Start/pause/resume/stop timer |
| BrewStepGuideView | Inside AddBrewLogView | Inline | Step-by-step method guidance |
| BrewLogDetailView | Tap brew row | Navigation push | Full brew details, edit, share |
| TastingNoteEntryView | Brew detail | Sheet | Add/edit tasting notes |
| FlavorWheelView | Inside TastingNoteEntryView | Inline | SCA 2016 interactive flavor selector |
| FlavorProfileView | Brew detail | Inline | Spider chart of tasting attributes |

### 5.2 Tab 2 — Beans

| Screen | Access | Type | Purpose |
|--------|--------|------|---------|
| BeanListView | Tab bar | Root | Searchable bean inventory (active & archived) |
| AddBeanView | "+" → Manual | Sheet | Manually add a new coffee bean |
| BagScannerView | "+" → Scan Bag | Sheet | Camera OCR to scan bag label |
| ScanResultReviewView | After scan | Navigation push | Review and confirm parsed bag data |
| BeanDetailView | Tap bean row | Navigation push | Full bean details, freshness, edit, archive |
| FreshnessIndicatorView | Bean detail / row | Inline | Visual days-since-roast indicator |

### 5.3 Sidebar — Equipment

| Screen | Access | Type | Purpose |
|--------|--------|------|---------|
| MethodListView | Sidebar → Methods | Full modal | List of brew methods with usage stats |
| MethodDetailView | Tap method row | Navigation push | Method details, parameters, edit |
| AddMethodView | "+" in Methods | Sheet | Add a new brew method |
| GrinderListView | Sidebar → Grinders | Full modal | List of grinders with usage stats |
| GrinderDetailView | Tap grinder row | Navigation push | Grinder details, setting ranges, edit |
| AddGrinderView | "+" in Grinders | Sheet | Add a new grinder |
| EquipmentPhotoPickerView | Equipment detail | Sheet | Photo selection for equipment |

### 5.4 Sidebar — Analysis

| Screen | Access | Type | Purpose |
|--------|--------|------|---------|
| StatisticsDashboardView | Sidebar → Statistics | Full modal | Charts, aggregates, AI pattern insights |
| BrewComparisonView | Sidebar → Compare | Full modal | Side-by-side comparison of two brews |

### 5.5 Sidebar — Other

| Screen | Access | Type | Purpose |
|--------|--------|------|---------|
| ExportView | Sidebar → Export | Full modal | Export brews as CSV or PDF |
| SettingsView | Sidebar → Settings | Full modal | App preferences (dark mode, units, etc.) |

---

## 6. User Flows

### Flow A — Log a Brew (Core)
```
Brews Tab
  → Tap "+"
  → AddBrewLogView (Sheet)
      ├── Select brew method
      ├── Select coffee bean
      ├── Select grinder
      ├── Enter parameters (dose, water, temperature, grind setting)
      ├── [Optional] Start timer / follow step guide
      ├── [Optional] View AI suggestion banner
      ├── Enter rating & notes
      ├── [Optional] Add photo
      └── Save
          → BrewLogDetailView
              └── [Optional] Add tasting notes
                    → TastingNoteEntryView (Sheet)
                        ├── Acidity / Body / Sweetness sliders
                        ├── FlavorWheelView (SCA 2016)
                        ├── Custom flavor tags
                        └── Freeform notes (AI flavor extraction)
```

### Flow B — Add a Coffee Bean
```
Beans Tab
  → Tap "+"
  ├── Manual Entry
  │     → AddBeanView (Sheet)
  │           Fields: name, roaster, origin, variety, roast level,
  │                   processing method, roast date, notes, photo
  └── Scan Bag Label
        → BagScannerView (Sheet)
              → Camera OCR
              → ScanResultReviewView
                    → Review & confirm parsed data
                    → Save bean
```

### Flow C — Review Analytics
```
Sidebar → Statistics
  → StatisticsDashboardView
      ├── Summary cards (total brews, avg rating, top method/bean)
      ├── Method distribution chart
      ├── Rating trend (line chart)
      ├── Brew frequency histogram
      ├── Top 5 beans used
      └── AI brewing pattern cards
```

### Flow D — Compare Two Brews
```
Sidebar → Compare Brews
  → BrewComparisonView
      ├── Select Brew A
      ├── Select Brew B
      └── Side-by-side view
            ├── Tasting attribute comparison
            ├── Flavor tags overlap
            ├── Brew parameters diff
            └── Spider charts
```

### Flow E — Export Data
```
Sidebar → Export
  → ExportView
      ├── Select format (CSV / PDF)
      ├── Select brews to include
      └── Share / Save
```

---

## 7. Data Model Summary

| Entity | Key Attributes | Relationships |
|--------|---------------|---------------|
| **BrewLog** | dose, waterAmount, yieldAmount, brewTime, waterTemperature, grinderSetting, rating, notes, photo | → BrewMethod, Grinder, CoffeeBean, TastingNote |
| **CoffeeBean** | name, roaster, origin, region, variety, processingMethod, roastLevel, roastDate, isArchived | ← BrewLog (many) |
| **BrewMethod** | name, category, brewCount, lastUsedDate, photo | ← BrewLog (many) |
| **Grinder** | name, type, settingMin, settingMax, settingStep, brewCount, lastUsedDate, photo | ← BrewLog (many) |
| **TastingNote** | acidity (1–5), body (1–5), sweetness (1–5), flavorTags, freeformNotes | ↔ BrewLog (one-to-one) |

---

## 8. Navigation Modalities

| Modality | Used For |
|----------|----------|
| **Tab Bar** | Brews ↔ Beans switching |
| **Navigation Push** | Detail views within a tab (brew detail, bean detail, equipment detail) |
| **Sheet** | Create/add forms (AddBrewLog, AddBean, TastingNotes, AddMethod, AddGrinder) |
| **Full Modal** | Sidebar destinations (Statistics, Compare, Export, Settings, Equipment lists) |
| **Inline (embedded)** | Timer, step guide, flavor wheel, spider chart, freshness indicator |

---

## 9. AI & Smart Features

| Feature | Where | Function |
|---------|-------|----------|
| Brew Suggestion Banner | AddBrewLogView | Suggests parameters based on brewing history |
| Flavor Extractor | TastingNoteEntryView | Extracts flavor tags from freeform text |
| Brew Pattern Analyzer | StatisticsDashboardView | Identifies patterns in brew history |
| Bag Label OCR | BagScannerView | Parses coffee bag text into structured bean data |
| Freshness Calculator | BeanDetailView / BeanRow | Computes days-since-roast and visual freshness level |

---

## 10. Empty States

Every list view implements `EmptyStateView` with context-appropriate messaging and a primary action CTA:

| Screen | Empty Message Trigger | CTA |
|--------|----------------------|-----|
| BrewLogListView | No brews logged | Log First Brew |
| BeanListView | No beans added | Add First Bean |
| MethodListView | No methods saved | Add Method |
| GrinderListView | No grinders saved | Add Grinder |
| StatisticsDashboardView | Not enough brew data | — |
| BrewComparisonView | Fewer than 2 brews | — |

---

## 11. Accessibility

- All interactive elements have `AccessibilityIdentifiers` defined in `AccessibilityIdentifiers.swift`
- UI Tests cover: BeanUITests, BrewLogUITests, EquipmentUITests, SetupWizardUITests, ScreenshotTests
- Star rating, sliders, and flavor wheel support accessibility labels

---

## 12. Settings & Preferences (AppStorage)

| Key | Type | Purpose |
|-----|------|---------|
| `hasCompletedSetup` | Bool | Controls onboarding gate |
| Dark mode preference | String/Bool | UI color scheme |
| Units (ml/oz, °C/°F) | String | Display unit preference |

---

## 13. Component Library

| Component | Purpose |
|-----------|---------|
| EmptyStateView | Reusable empty list with icon, message, and optional CTA |
| StarRatingView | 1–5 star input |
| AttributeSliderView | 1–5 slider for tasting attributes |
| FlavorTagChipView | Individual flavor tag pill |
| FlavorTagFlowView | Responsive wrapping layout for tag sets |
| SpiderChartView | Radar chart for acidity/body/sweetness |
| BrewPatternCard | AI insight card display |
| BrewSuggestionBanner | Contextual AI suggestion in brew form |
| FreshnessIndicatorView | Visual freshness bar with color coding |
| EquipmentRow | Equipment list row with photo, stats, icon |
| SyncStatusView | Network/sync status indicator |
| MonochromeStyle | Shared styling utilities |
