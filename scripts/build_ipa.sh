#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Generating Xcode project with XcodeGen..."
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "请先安装 xcodegen: brew install xcodegen"
  exit 1
fi

xcodegen generate

echo "==> Building (unsigned)..."
mkdir -p dist build

# 使用模拟器或通用 iOS 设备，关闭签名
xcodebuild \
  -project Resonance.xcodeproj \
  -scheme Resonance \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH=$(find build/DerivedData/Build/Products -name "Resonance.app" | head -1)

if [[ -z "$APP_PATH" ]]; then
  echo "错误：没有找到 Resonance.app"
  exit 1
fi

echo "==> Packaging IPA..."
rm -rf dist/Payload dist/Resonance-unsigned.ipa
mkdir -p dist/Payload
cp -R "$APP_PATH" dist/Payload/
cd dist
zip -qr Resonance-unsigned.ipa Payload
rm -rf Payload

echo "==> Done: dist/Resonance-unsigned.ipa"
ls -lh Resonance-unsigned.ipa
shasum -a 256 Resonance-unsigned.ipa > Resonance-unsigned.ipa.sha256
cat Resonance-unsigned.ipa.sha256
