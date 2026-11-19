#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
swift build -c release
app="$(pwd)/dist/贪吃蛇.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/SnakeMac "$app/Contents/MacOS/SnakeMac"
iconset="$(pwd)/.build/AppIcon.iconset"
mkdir -p "$iconset"
swift scripts/prepare-icon.swift Assets/AppIcon-colorful-v3.png "$iconset"
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
<key>CFBundleShortVersionString</key><string>1.0.2</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
printf 'Built: %s\n' "$app"
