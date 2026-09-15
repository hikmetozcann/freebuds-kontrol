# Development and releases

## Local workflow

```sh
./build.sh
"build/FreeBuds Kontrol.app/Contents/MacOS/FreeBudsKontrol" --self-test
./Tools/package.sh
```

`VERSION` is the single release-version source. `Resources/Info.plist` is copied and stamped by the build. `Tools/make-icon.swift` generates the icon; no prebuilt vendor image is required. Build artifacts belong in `build/` and `dist/`, which are ignored by git.

`ARCH=arm64` and `ARCH=x86_64` select compilation/packaging architecture. Run executable tests on the corresponding architecture; cross-compilation alone is not a runtime check. CI uses native runners for both.

## Hardware testing

Close the GUI and other earbud managers first. Pair/connect the supported headset to the Mac. `--snapshot` reads selected information; it intentionally omits the Bluetooth address and serial number. Review any output before sharing it.

`--smoke-test` temporarily writes ANC/EQ/gesture/latency settings and reads them back. It attempts restoration on a failed verification, but restoration cannot be guaranteed if the accessory disconnects or powers off. Keep the earbuds powered and connected, do not change settings from another app during the test, and check the final reported state. It is a developer command, not an installation requirement, and is never invoked by CI.

## Interface previews

```sh
./Tools/render-previews.sh
```

This builds an offscreen renderer using the same SwiftUI views and original artwork. It uses fixed example battery/settings data and the reduced-transparency appearance, since native glass requires onscreen window compositing. It does not open a Bluetooth link, order a window onscreen or capture the user's desktop. Inspect both PNGs before committing them.

## Publishing

1. Update `VERSION`, `CHANGELOG.md` and `docs/releases/v<VERSION>.md` in a reviewed commit on `main`.
2. Wait for **macOS build** to pass for that exact commit on both architectures.
3. Run **Publish checked release** from Actions, with `main` selected. A maintainer can alternatively run `python3 Tools/release.py` from that same commit with authenticated `gh`.
4. The publisher verifies main's SHA, an unused version tag, successful push-event CI, both job conclusions, expected artifact filenames and SHA-256 checksums. It then creates a versioned tag/release using those CI artifacts. It does not rebuild or upload a developer's local diagnostic files.

Do not reuse a published version number. Release ZIPs contain the app, GPL license, notices and installation/source-code links. GitHub's tag source archives provide the corresponding source for that release. There is no Developer ID/notarization secret configured; ad hoc signing and its first-launch limitations are stated in the README.

The publication workflow is manually triggered, not scheduled. CI is read-only; only the publishing job receives repository-content write permission. Actions are pinned to commit SHAs and Dependabot proposes updates.
