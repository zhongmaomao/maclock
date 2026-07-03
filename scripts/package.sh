#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

swift build -c release --product MacLock
bin_dir="$(swift build -c release --show-bin-path)"
app="${1:-.build/MacLock.app}"

mkdir -p "$app/Contents/MacOS"
cp "$bin_dir/MacLock" "$app/Contents/MacOS/MacLock"
chmod +x "$app/Contents/MacOS/MacLock"

cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacLock</string>
    <key>CFBundleIdentifier</key>
    <string>local.maclock.MacLock</string>
    <key>CFBundleName</key>
    <string>MacLock</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "$app"
