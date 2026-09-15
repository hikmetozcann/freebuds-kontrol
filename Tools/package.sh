#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
FREEBUDS_ROOT=${0:A:h:h}
FREEBUDS_ARCH=${ARCH:-$(uname -m)}
FREEBUDS_VERSION=$(<"$FREEBUDS_ROOT/VERSION")
FREEBUDS_APP="$FREEBUDS_ROOT/build/FreeBuds Kontrol.app"
[[ -d "$FREEBUDS_APP" ]] || { print -u2 'Run ./build.sh first'; exit 1; }
FREEBUDS_ACTUAL=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$FREEBUDS_APP/Contents/Info.plist")
[[ "$FREEBUDS_ACTUAL" == "$FREEBUDS_VERSION" ]] || { print -u2 'Bundle version mismatch'; exit 1; }
[[ "$(lipo -archs "$FREEBUDS_APP/Contents/MacOS/FreeBudsKontrol")" == "$FREEBUDS_ARCH" ]] || { print -u2 'Bundle architecture mismatch'; exit 1; }
codesign --verify --deep --strict "$FREEBUDS_APP"
FREEBUDS_STAGE=$(mktemp -d)
trap 'rm -rf "$FREEBUDS_STAGE"' EXIT
mkdir -p "$FREEBUDS_ROOT/dist"
ditto "$FREEBUDS_APP" "$FREEBUDS_STAGE/FreeBuds Kontrol.app"
cp "$FREEBUDS_ROOT/LICENSE" "$FREEBUDS_ROOT/NOTICE.md" "$FREEBUDS_STAGE/"
cat > "$FREEBUDS_STAGE/INSTALL.txt" <<TXT
FreeBuds Kontrol $FREEBUDS_VERSION ($FREEBUDS_ARCH)
Move FreeBuds Kontrol.app to Applications, then open it.
macOS 14 or later. FreeBuds SE 4 ANC (BTFT0026) only. Interface: Turkish.
This build is ad hoc signed, not Apple-notarized. See the README for first launch.
Source code for this exact release (GPL-3.0-only):
https://github.com/hikmetozcann/freebuds-kontrol/tree/v$FREEBUDS_VERSION
Help: https://github.com/hikmetozcann/freebuds-kontrol#installation
TXT
FREEBUDS_ZIP="FreeBuds-Kontrol-$FREEBUDS_VERSION-$FREEBUDS_ARCH.zip"
ditto -c -k --norsrc "$FREEBUDS_STAGE" "$FREEBUDS_ROOT/dist/$FREEBUDS_ZIP"
(cd "$FREEBUDS_ROOT/dist" && shasum -a 256 "$FREEBUDS_ZIP" > "SHA256SUMS-$FREEBUDS_ARCH.txt")
print "$FREEBUDS_ROOT/dist/$FREEBUDS_ZIP"
