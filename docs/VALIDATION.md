# Validation scope

## Hardware observations

Development on 14–15 September 2026 used a FreeBuds SE 4 ANC (`BTFT0026`) with firmware `1.9.0.199`, on an Apple Silicon Mac running macOS 26.3.

Battery/model reads, ANC intensity, EQ, left double/triple/hold gestures, noise-mode cycling and the low-latency setting were exercised against the real device. Each write was read back and the original values were restored. The final settings snapshot matched the initial snapshot. Awareness/off/ANC switching and call-gesture enable/disable were also checked in the GUI.

The 1.1 interface was checked in light/dark appearance with live battery values and while disconnected. The public 1.2.0 release changes artwork, reduced-transparency color resolution, app identity and distribution tooling; the transport and model were retained from that hardware-validated implementation. Protocol facts and limitations are documented without claiming every setting combination was tested.

## Automated checks

CI builds and runs pure protocol checks on Apple Silicon and Intel macOS runners. Checks cover a CRC reference vector, all fragment boundaries, concatenated frames, resynchronization after corrupted input, malformed TLVs and command-specific response/ACK acceptance. CI also validates the bundle signature, property list and distributable archive.

These checks do not connect to earbuds or establish that all supported macOS releases work with physical hardware. Both release archives must come from a successful build of the exact main commit being released.

## Limits

- Other firmware, earbud models and every gesture combination have not been validated.
- Audio latency, sound quality and ANC effectiveness have not been measured.
- Actual calls and the physical result of every touch gesture have not been evaluated.
- The explicit Mac-connect action after a complete baseband disconnection is not fully validated.
- The older macOS material fallback and every accessibility combination have not been checked on physical Macs.
- Multipoint, cross-device handoff and firmware modification are outside the implementation.

Interface images in the README are rendered offscreen from the app's views using documented example values and reduced transparency. They are not hardware-test evidence.
