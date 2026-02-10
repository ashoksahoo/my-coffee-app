# Coffee Journal

A minimal, monochrome iOS app for tracking coffee brewing from grind to cup.

![Coffee Journal Screenshots](screenshots/screenshot-1.png)

## Overview

Coffee Journal is a personal coffee brewing tracker that captures the full brewing process — equipment, beans, parameters, and tasting notes. Built with a local-first approach featuring iCloud sync across all your iOS devices.

**Key Philosophy:** Remember and improve your coffee brewing by tracking what works. Every cup is a learning opportunity.

## Features

### Core Functionality
- **Equipment Management** - Track your grinders, brew methods (V60, Aeropress, espresso, etc.)
- **Coffee Tracking** - Log roasters, origins, roast dates, and coffee varieties
- **Brew Logging** - Record complete brew parameters:
  - Grind settings
  - Dose and yield measurements
  - Water temperature and brew time
  - Photos of your brew
- **Tasting Notes** - Structured and freeform notes:
  - 1-5 scale ratings (acidity, body, sweetness)
  - SCA flavor wheel tags
  - Custom flavor descriptors
  - Freeform notes
- **Search & Filter** - Find brews by coffee, method, or date
- **Apple Intelligence Insights** - On-device ML extracts patterns and suggests brew parameters

### Technical Features
- **Local-First Storage** - Core Data with SwiftData
- **iCloud Sync** - Seamless sync via CloudKit across iPhone and iPad
- **Offline-First** - Full functionality without internet connection
- **Privacy-Focused** - All data stays in your iCloud, no external servers
- **Monochrome Design** - E-ink friendly, black and white aesthetic

## Screenshots

<p float="left">
  <img src="screenshots/screenshot-1.png" width="250" />
  <img src="screenshots/screenshot-2.png" width="250" />
</p>

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0+
- Active Apple Developer account (for running on device)

## Building from Source

### Prerequisites

1. Install Xcode 15.0 or later from the Mac App Store
2. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

### Clone and Build

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/coffee-app.git
   cd coffee-app
   ```

2. Open the project in Xcode:
   ```bash
   open CoffeeJournal.xcodeproj
   ```

3. Configure signing:
   - Select the project in Xcode's navigator
   - Choose your target (CoffeeJournal)
   - Go to "Signing & Capabilities"
   - Select your development team
   - Xcode will automatically manage provisioning profiles

4. Build and run:
   - Select your target device or simulator
   - Press `Cmd + R` or click the Play button

### Building from Command Line

Build for simulator:
```bash
xcodebuild -project CoffeeJournal.xcodeproj \
  -scheme CoffeeJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

Run tests:
```bash
xcodebuild test -project CoffeeJournal.xcodeproj \
  -scheme CoffeeJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

### iCloud Configuration

To enable iCloud sync:

1. Enable iCloud capability in your Apple Developer account
2. In Xcode, under "Signing & Capabilities":
   - Add "iCloud" capability
   - Enable "CloudKit"
   - Ensure the CloudKit container is selected

Note: iCloud sync requires running on a physical device with an Apple ID signed in.

## Tech Stack

- **Language:** Swift 6.0
- **UI Framework:** SwiftUI
- **Persistence:** Core Data with SwiftData
- **Cloud Sync:** CloudKit
- **ML/AI:** Apple Intelligence (on-device)
- **Platform:** iOS 17+

## Project Structure

```
CoffeeJournal/
├── Models/           # Core Data models and data structures
├── Views/            # SwiftUI views and screens
├── ViewModels/       # View models and business logic
├── Services/         # CloudKit sync, insights, data services
├── Utilities/        # Helper functions and extensions
└── Resources/        # Assets and configuration files
```

## Development Status

Currently in active development. This is a personal project built for tracking my own coffee brewing, with plans for App Store release in the future.

### Roadmap

- **v1 (Current):** Personal use - brew logging, equipment tracking, iCloud sync
- **v2:** Bean inventory management, enhanced insights
- **v3:** Bluetooth scale integration, App Store polish, public release

## Contributing

This is currently a personal project. If you have suggestions or find issues, feel free to open an issue or discussion.

## Privacy

- All data is stored locally on your device
- iCloud sync uses your personal iCloud account
- No data is sent to external servers
- Apple Intelligence runs on-device only
- No analytics or tracking

## License

[Choose your license - MIT, Apache 2.0, or other]

## Acknowledgments

- SCA Flavor Wheel for coffee tasting vocabulary
- The coffee community for inspiration

---

**Note:** This app is not available on the App Store yet. To use it, you must build from source using the instructions above.
