# Attribution and distribution

**FreeBuds Kontrol** — Copyright © 2026 hikmetozcann and contributors.
Source code, original illustrations, icon generator and documentation in this repository are distributed under **GPL-3.0-only**. See [LICENSE](LICENSE).

## OpenFreebuds

Bluetooth packet layout and Huawei command meanings were studied in [OpenFreebuds](https://github.com/melianmiko/OpenFreebuds), especially its SE 4 driver and Huawei handlers at revision [`dcd519190d24cccd2bf87841be74b3f73d04e762`](https://github.com/melianmiko/OpenFreebuds/tree/dcd519190d24cccd2bf87841be74b3f73d04e762). Thanks to the OpenFreebuds contributors for documenting device interoperability.

This project implements a Swift transport and macOS interface. It does not bundle or execute the OpenFreebuds Python application. The GPLv3 project license is chosen to keep this work shareable and compatible with that reference. Upstream authors retain rights in their work.

## Artwork and platform components

`Sources/Artwork.swift` and `Tools/make-icon.swift` draw original, stylized illustrations. They do not identify the physical device's color. No Huawei photographs, logos, firmware or proprietary binaries are included in this repository or its release archives.

SF Symbols and macOS interface components are requested from the installed operating system at runtime; their artwork is not redistributed as separate assets. Apple's system frameworks remain under their respective terms.

HUAWEI and FreeBuds are trademarks of their respective owners, used here to identify supported hardware. This is an independent community project and is not affiliated with or endorsed by Huawei or Apple.
