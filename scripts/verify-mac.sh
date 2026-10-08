#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]] || ! command -v xcodebuild >/dev/null; then
  echo 'This check requires macOS with Xcode selected via xcode-select.' >&2
  exit 1
fi
xcodebuild -version
swift --version
plutil -lint App/Info.plist TravelMemory.xcodeproj/project.pbxproj App/Resources/PrivacyInfo.xcprivacy
swift test
xcodebuild -project TravelMemory.xcodeproj -scheme TravelMemory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  DEVICE=$(xcrun simctl list devices available -j | python3 -c 'import sys,json; d=json.load(sys.stdin); print(next((v["udid"] for k,vs in d["devices"].items() if "iOS" in k for v in vs if "iPhone" in v["name"]), ""))')
fi
if [[ -z "$DEVICE" ]]; then
  echo 'Build finished, but no available iPhone Simulator. Install an iOS runtime in Xcode Settings > Components.' >&2
  exit 2
fi
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b
xcodebuild -project TravelMemory.xcodeproj -scheme TravelMemory -configuration Debug -destination "platform=iOS Simulator,id=$DEVICE" -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test
xcrun simctl install "$DEVICE" DerivedData/Build/Products/Debug-iphonesimulator/TravelMemory.app
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' DerivedData/Build/Products/Debug-iphonesimulator/TravelMemory.app/Info.plist)
xcrun simctl launch "$DEVICE" "$BUNDLE_ID"
open -a Simulator
