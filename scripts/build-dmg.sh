#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

./scripts/build-app.sh

app="$(pwd)/dist/SnakeMac.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
architecture=$(uname -m)
name="SnakeMac-${version}-${architecture}.dmg"
staging=$(mktemp -d "$(pwd)/.build/dmg-stage.XXXXXX")
trap 'rm -rf "$staging"' EXIT

ditto "$app" "$staging/SnakeMac.app"
ln -s /Applications "$staging/Applications"
cat > "$staging/安装说明.txt" <<'TEXT'
贪吃蛇 · SnakeMac

安装：将 SnakeMac.app 拖入 Applications（应用程序）文件夹。
随后在「应用程序」文件夹中打开 SnakeMac。
安装完成后，可在 Finder 中推出此磁盘映像。

系统要求：macOS 13 或更高版本；处理器架构以安装包文件名为准。

操作：方向键 / WASD 移动，空格暂停或继续，⌘N 开始新游戏。

此构建使用本地临时签名，尚未进行 Developer ID 签名和 Apple 公证。
TEXT

codesign --verify --deep --strict "$staging/SnakeMac.app"
hdiutil create -volname "SnakeMac ${version}" -srcfolder "$staging" \
    -fs HFS+ -format UDZO -ov "dist/$name"
hdiutil verify "dist/$name"
(cd dist && shasum -a 256 "$name" > "$name.sha256")
printf 'Installer: %s/dist/%s\n' "$(pwd)" "$name"
