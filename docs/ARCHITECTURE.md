# Architecture

FreeBuds Kontrol is a Swift executable packaged as an AppKit accessory app. There is no web view, background service or Python runtime.

| Component | Responsibility |
| --- | --- |
| `Sources/Protocol.swift` | Framing, CRC16/XMODEM, incremental decoding, command/field definitions |
| `Sources/Bluetooth.swift` | Paired-device discovery, RFCOMM lifecycle, one outstanding request, deadlines and write/readback verification |
| `Sources/Model.swift` | Observable device state, polling and serialized user changes |
| `Sources/Views.swift` | Turkish controls and connection/unknown states |
| `Sources/Surfaces.swift` | Native materials, accessibility preferences, window appearance and reusable controls |
| `Sources/Artwork.swift` | Original vector earbud illustration |
| `Sources/main.swift` | Menu bar/window lifecycle and command-line entry points |
| `Sources/Checks.swift` | Pure protocol checks and explicitly invoked hardware diagnostics |

## Transport

The paired SE 4 exposes the SPP service (UUID `0x1101`) on RFCOMM channel 1. The model information response must identify `BTFT0026` before settings can be written. Successful writes must be followed by a matching read response; the view reflects reported state instead of optimistic confirmation.

A frame starts with `0x5A`, a two-byte big-endian length and `0x00`, followed by a two-byte command, one-byte key/length TLVs and a two-byte CRC16/XMODEM. The parser accepts fragmented/concatenated packets and checks CRC/TLV bounds. See `Protocol.swift` and the pinned OpenFreebuds reference in `NOTICE.md` for individual commands.

All link operations/callbacks use the main run loop. The model serializes polling and changes so there is one outstanding request. Closing the application closes its control channel, rather than intentionally disconnecting the underlying audio link. A dropped channel clears displayed capability values.

## Materials

macOS 26's public `NSGlassEffectView` is resolved by its Objective-C runtime name. Its documented properties are guarded before use so the app can still be built with the older macOS SDK. Earlier macOS releases use `NSVisualEffectView`. Appearance overrides are applied to the window and glass views explicitly; selecting System clears the override. See Apple's [material guidance](https://developer.apple.com/design/human-interface-guidelines/materials).

## Extension boundaries

Do not broaden model acceptance without a separately validated capability map. A command being present in another FreeBuds driver does not establish support on the SE 4. Keep raw diagnostics out of issue templates and never add device-specific addresses or serials to source.
