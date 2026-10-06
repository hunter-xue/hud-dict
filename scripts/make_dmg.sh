#!/bin/sh
# 构建 Release 版 HudDict 并打包成 DMG。
#
# 用法：scripts/make_dmg.sh
# 产物：build/HudDict-<version>.dmg
#
# 说明：
# - 仅支持 arm64（Apple Silicon）。
# - 无开发者账号，使用 ad-hoc 签名（codesign -s -）。别的机器首次打开需
#   右键「打开」或在「系统设置 → 隐私与安全性」中点「仍要打开」绕过 Gatekeeper。
# - 依赖系统自带的 xcodebuild、codesign、hdiutil。

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="HudDict"
VOL_NAME="HudDict"
BUILD_DIR="$ROOT/build"
DERIVED="$BUILD_DIR/DerivedData"

# 从 Info.plist 读取版本号
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' HudDict/App/Info.plist)"
DMG_PATH="$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"

echo "==> 清理旧产物"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> 确保工程存在（由 project.yml 生成）"
if [ ! -d HudDict.xcodeproj ]; then
  xcodegen generate
fi

echo "==> Release 构建（arm64）"
xcodebuild \
  -project HudDict.xcodeproj \
  -scheme HudDict \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  build

APP_SRC="$DERIVED/Build/Products/Release/${APP_NAME}.app"
if [ ! -d "$APP_SRC" ]; then
  echo "构建产物不存在：$APP_SRC" >&2
  exit 1
fi

echo "==> 准备打包目录"
STAGE="$BUILD_DIR/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP_SRC" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> ad-hoc 重签（无开发者账号）"
codesign --force --deep --sign - "$STAGE/${APP_NAME}.app"
codesign --verify --verbose "$STAGE/${APP_NAME}.app" || true

echo "==> 生成 DMG"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo ""
echo "完成：$DMG_PATH"
echo "（未签名版本，别的机器首次打开需右键「打开」绕过 Gatekeeper）"