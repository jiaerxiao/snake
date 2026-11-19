#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
swift build -c release
app="$(pwd)/dist/SnakeMac.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/SnakeMac "$app/Contents/MacOS/SnakeMac"
iconset="$(pwd)/.build/AppIcon.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" Assets/AppIcon-colorful-v3.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    retina=$((size * 2))
    sips -z "$retina" "$retina" Assets/AppIcon-colorful-v3.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>SnakeMac</string>
<key>CFBundleIdentifier</key><string>com.local.snakemac</string>
<key>CFBundleName</key><string>贪吃蛇</string>
<key>CFBundleDisplayName</key><string>贪吃蛇</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
printf 'Built: %s\n' "$app"
