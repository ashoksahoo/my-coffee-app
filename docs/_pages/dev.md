---
layout: page
title: Customise the Flavour Wheel
include_in_header: true
---

# Customising the Flavour Wheel

Coffee Journal ships with the SCA 2016 flavour wheel, but the entire hierarchy lives in a single JSON file — no Swift changes needed.

<br>

## The Data File

**`CoffeeJournal/Resources/FlavorWheel.json`**

Three-level hierarchy:

```
category
  └── subcategory
        └── descriptor  (selectable leaf node)
```

Each node follows this shape:

```json
{
  "id": "fruity.berry.strawberry",
  "name": "Strawberry",
  "children": []
}
```

- **`id`** — dot-path, must be unique. Used for selection state and color lookup.
- **`name`** — display label shown on the wheel.
- **`children`** — nested nodes, empty array for selectable descriptors.

The top-level `id` (first segment) drives the colour assigned to the whole branch.

<br>

## Making Changes

**Option A — Edit and rebuild (simplest)**

1. Open `CoffeeJournal/Resources/FlavorWheel.json`
2. Add, remove, or rename nodes
3. Build and run in Xcode

**Option B — Hot-swap at runtime (no rebuild)**

Drop a modified `FlavorWheel.json` into the app's Documents directory, then call:

```swift
FlavorWheel.reload()
```

The app picks up the new data immediately. Useful for rapid iteration in the Simulator — drag the file straight into the sandbox via Xcode's Device & Simulators window.

<br>

## Changing Colours

Each top-level category gets a colour defined in `FlavorWheelView.swift`:

```swift
private static let categoryColors: [String: Color] = [
    "floral":           Color(hue: 0.82, saturation: 0.52, brightness: 0.88),
    "fruity":           Color(hue: 0.02, saturation: 0.82, brightness: 0.90),
    // ...
]
```

Add an entry matching your new top-level `id` to assign a colour. Any unrecognised id falls back to grey.

<br>

## Preview Without Xcode

**[Open Interactive Flavour Wheel →](/dev/flavor-wheel.html)**

A browser-based replica of the in-app wheel. Tap through the same three-level drill-down to see exactly how your data will look and feel before building.

The preview embeds the JSON inline — after editing `FlavorWheel.json`, paste the updated contents into the `const WHEEL_DATA` block at the top of `docs/dev/flavor-wheel.html` to see your changes.

<br>

## Adding a New Category

1. Add a top-level object to `FlavorWheel.json` with a unique `id`
2. Add a matching colour entry in `FlavorWheelView.swift`
3. Rebuild (or hot-swap via Documents)

The wheel automatically divides evenly across however many top-level categories exist.
