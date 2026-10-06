#!/bin/sh
# 从源 PNG 生成 macOS AppIcon 图标集。
#
# 用法：scripts/make_icon.sh [源 PNG] [输出 appiconset 目录]
# 默认：Assets/AppIcon-source-1024.png -> HudDict/App/Assets.xcassets/AppIcon.appiconset
#
# 步骤：源图切圆角 -> 生成全套尺寸 -> 写入 Contents.json。
# 依赖系统自带的 sips、swiftc。

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/Assets/AppIcon-source-1024.png}"
DEST="${2:-$ROOT/HudDict/App/Assets.xcassets/AppIcon.appiconset}"

if [ ! -f "$SRC" ]; then
  echo "找不到源图：$SRC" >&2
  exit 1
fi

mkdir -p "$DEST" "$ROOT/.build"

# 1. 切 macOS 圆角（四角透明），输出 1024 主图
swiftc -O "$ROOT/scripts/round_icon.swift" -o "$ROOT/.build/round_icon"
"$ROOT/.build/round_icon" "$SRC" "$DEST/icon_512x512@2x.png"

# 2. 生成其余尺寸
MASTER="$DEST/icon_512x512@2x.png"
sips -z 16 16   "$MASTER" --out "$DEST/icon_16x16.png"     >/dev/null
sips -z 32 32   "$MASTER" --out "$DEST/icon_16x16@2x.png"  >/dev/null
sips -z 32 32   "$MASTER" --out "$DEST/icon_32x32.png"     >/dev/null
sips -z 64 64   "$MASTER" --out "$DEST/icon_32x32@2x.png"  >/dev/null
sips -z 128 128 "$MASTER" --out "$DEST/icon_128x128.png"   >/dev/null
sips -z 256 256 "$MASTER" --out "$DEST/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER" --out "$DEST/icon_256x256.png"   >/dev/null
sips -z 512 512 "$MASTER" --out "$DEST/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER" --out "$DEST/icon_512x512.png"   >/dev/null

# 3. Contents.json
cat > "$DEST/Contents.json" <<'JSON'
{
  "images" : [
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16.png", "scale" : "1x" },
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16@2x.png", "scale" : "2x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32.png", "scale" : "1x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32@2x.png", "scale" : "2x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128.png", "scale" : "1x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128@2x.png", "scale" : "2x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256.png", "scale" : "1x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256@2x.png", "scale" : "2x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512.png", "scale" : "1x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512@2x.png", "scale" : "2x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
JSON

echo "图标已生成到 $DEST"