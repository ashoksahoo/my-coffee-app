#!/bin/bash
set -e

# Script to generate screenshots for README and App Store
# Usage: ./generate-screenshots.sh [device-name]

DEVICE="${1:-iPhone 17}"
SCHEME="CoffeeJournal"
PROJECT="CoffeeJournal.xcodeproj"
SCREENSHOTS_DIR="./screenshots"

echo "🎬 Generating screenshots for Coffee Journal..."
echo "📱 Device: $DEVICE"
echo ""

# Clean previous screenshots
if [ -d "$SCREENSHOTS_DIR" ]; then
    echo "🗑️  Cleaning old screenshots..."
    rm -rf "$SCREENSHOTS_DIR"/*
fi

mkdir -p "$SCREENSHOTS_DIR"

# Run screenshot tests
echo "🧪 Running UI tests with screenshot generation..."
xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -only-testing:CoffeeJournalUITests/ScreenshotTests \
    -derivedDataPath ./DerivedData \
    2>&1 | grep -E "Test (Suite|Case)|Screenshot|Wrote screenshot|error|failed" || true

# Find test attachments directory
DERIVED_DATA="./DerivedData"
ATTACHMENTS_DIR=$(find "$DERIVED_DATA" -path "*/Attachments" -type d | head -1)

if [ -z "$ATTACHMENTS_DIR" ]; then
    echo "❌ Could not find test attachments directory"
    echo "Screenshots may not have been generated successfully"
    exit 1
fi

echo ""
echo "📸 Extracting screenshots from test attachments..."

# Copy screenshots from attachments to screenshots directory
SCREENSHOT_COUNT=0
for screenshot in "$ATTACHMENTS_DIR"/*.png; do
    if [ -f "$screenshot" ]; then
        filename=$(basename "$screenshot")
        # Extract the friendly name from the attachment
        if [[ "$filename" =~ Screenshot_(.+)_.*\.png ]]; then
            friendly_name="${BASH_REMATCH[1]}"
            cp "$screenshot" "$SCREENSHOTS_DIR/${friendly_name}.png"
            echo "  ✓ $friendly_name.png"
            ((SCREENSHOT_COUNT++))
        fi
    fi
done

echo ""
echo "✅ Generated $SCREENSHOT_COUNT screenshots in $SCREENSHOTS_DIR/"
echo ""
echo "Next steps:"
echo "  1. Review screenshots in the screenshots/ directory"
echo "  2. Update README.md to reference your favorite screenshots"
echo "  3. Commit the screenshots to your repository"
echo ""
echo "To generate for a different device:"
echo "  ./generate-screenshots.sh \"iPhone 17 Pro Max\""
