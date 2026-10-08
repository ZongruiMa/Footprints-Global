#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]] || ! command -v xcodebuild >/dev/null; then
  echo 'Requires a macOS runner with Xcode.' >&2
  exit 1
fi
mkdir -p build-cloud/logs dist
xcodebuild -version | tee build-cloud/logs/xcode.txt
swift --version | tee build-cloud/logs/swift.txt
plutil -lint App/Info.plist TravelMemory.xcodeproj/project.pbxproj App/Resources/PrivacyInfo.xcprivacy
swift test 2>&1 | tee build-cloud/logs/core-tests.log

DEVICE=$(xcrun simctl list devices available -j | python3 -c 'import sys,json; d=json.load(sys.stdin); print(next((v["udid"] for k,vs in d["devices"].items() if "iOS" in k for v in vs if "iPhone" in v["name"]), ""))')
if [[ -z "$DEVICE" ]]; then
  echo 'No iPhone simulator is installed on this runner.' >&2
  exit 2
fi
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b
xcodebuild -project TravelMemory.xcodeproj -scheme TravelMemory \
  -configuration Debug -destination "platform=iOS Simulator,id=$DEVICE" \
  -derivedDataPath build-cloud/Simulator -resultBundlePath build-cloud/Tests.xcresult \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test \
  2>&1 | tee build-cloud/logs/ios-tests.log
xcrun simctl install "$DEVICE" build-cloud/Simulator/Build/Products/Debug-iphonesimulator/TravelMemory.app
for CASE in en-world ja-country:JPN ar-world; do
  LANGUAGE=${CASE%%-*}
  MAP=${CASE#*-}
  xcrun simctl terminate "$DEVICE" local.personal.travelmemory 2>/dev/null || true
  EXTRA=()
  if [[ "$LANGUAGE" == ar ]]; then EXTRA+=(--preview-settings); fi
  xcrun simctl launch "$DEVICE" local.personal.travelmemory --preview -interfaceLanguage "$LANGUAGE" -selectedMap "$MAP" "${EXTRA[@]}"
  sleep 5
  xcrun simctl io "$DEVICE" screenshot "build-cloud/simulator-${LANGUAGE}.png"
done

# An actual iphoneos/arm64 executable, not an iOS Simulator bundle.
# No Apple account, certificate, or signing secret is sent to GitHub.
xcodebuild -project TravelMemory.xcodeproj -scheme TravelMemory \
  -configuration Release -destination 'generic/platform=iOS' -sdk iphoneos \
  -derivedDataPath build-cloud/Device ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' \
  CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:-1}" build \
  2>&1 | tee build-cloud/logs/iphone-build.log
APP=build-cloud/Device/Build/Products/Release-iphoneos/TravelMemory.app
xcrun lipo "$APP/TravelMemory" -verify_arch arm64
python3 scripts/package-ipa.py "$APP" dist/Footprints.ipa
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  cat >> "$GITHUB_STEP_SUMMARY" <<'EOF'
## 足迹安装包已生成
Core 和 iOS 集成测试通过，已构建 iPhone arm64 Release 包。

下载本次运行的 **Footprints-iPhone** artifact，解压取得 **Footprints.ipa**。
这是未签名安装包，需要 Windows AltServer / iPhone AltStore 使用你自己的 Apple ID 签名安装。
不需要把 Apple ID、证书或密码放进 GitHub。完整步骤见包内 INSTALL-WINDOWS.md。

模拟器截图和测试报告保存在 Build-diagnostics。真机照片权限与实际相册仍需手机验收。
EOF
fi
