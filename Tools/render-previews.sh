#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
FREEBUDS_ROOT=${0:A:h:h}
mkdir -p "$FREEBUDS_ROOT/build" "$FREEBUDS_ROOT/docs/images"
FREEBUDS_SOURCES=("$FREEBUDS_ROOT"/Sources/*.swift)
FREEBUDS_SOURCES=("${(@)FREEBUDS_SOURCES:#*/main.swift}")
xcrun swiftc -swift-version 5 -D PREVIEW_RENDERER -O -framework AppKit -framework SwiftUI -framework IOBluetooth \
  "${FREEBUDS_SOURCES[@]}" "$FREEBUDS_ROOT/Tools/render-previews.swift" -o "$FREEBUDS_ROOT/build/preview-renderer"
for appearance in light dark; do
  "$FREEBUDS_ROOT/build/preview-renderer" "$appearance" "$FREEBUDS_ROOT/docs/images/$appearance.png"
done
