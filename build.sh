#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
FREEBUDS_ROOT=${0:A:h}
FREEBUDS_DEST=${1:-"$FREEBUDS_ROOT/build"}
FREEBUDS_ARCH=${ARCH:-$(uname -m)}
[[ "$FREEBUDS_ARCH" == arm64 || "$FREEBUDS_ARCH" == x86_64 ]] || { print -u2 'ARCH must be arm64 or x86_64'; exit 1; }
FREEBUDS_VERSION=$(<"$FREEBUDS_ROOT/VERSION")
[[ "$FREEBUDS_VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || { print -u2 'Invalid VERSION'; exit 1; }
FREEBUDS_APP="$FREEBUDS_DEST/FreeBuds Kontrol.app"
mkdir -p "$FREEBUDS_APP/Contents/MacOS" "$FREEBUDS_APP/Contents/Resources" "$FREEBUDS_DEST/generated"
xcrun swiftc -swift-version 5 -target "$FREEBUDS_ARCH-apple-macosx14.0" -O \
  -framework AppKit -framework SwiftUI -framework IOBluetooth \
  "$FREEBUDS_ROOT"/Sources/*.swift -o "$FREEBUDS_APP/Contents/MacOS/FreeBudsKontrol"
cp "$FREEBUDS_ROOT/Resources/Info.plist" "$FREEBUDS_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $FREEBUDS_VERSION" "$FREEBUDS_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $FREEBUDS_VERSION" "$FREEBUDS_APP/Contents/Info.plist"
xcrun swift "$FREEBUDS_ROOT/Tools/make-icon.swift" "$FREEBUDS_DEST/generated/AppIcon.iconset"
iconutil -c icns "$FREEBUDS_DEST/generated/AppIcon.iconset" -o "$FREEBUDS_APP/Contents/Resources/AppIcon.icns"
cp "$FREEBUDS_ROOT/LICENSE" "$FREEBUDS_ROOT/NOTICE.md" "$FREEBUDS_APP/Contents/Resources/"
codesign --force --sign - "$FREEBUDS_APP"
codesign --verify --deep --strict "$FREEBUDS_APP"
print "$FREEBUDS_APP"
