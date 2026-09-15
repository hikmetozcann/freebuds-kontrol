# Contributing

Thanks for helping make FreeBuds Kontrol useful and reliable. Small, focused pull requests are easiest to review.

1. Open an issue for a new feature, model or protocol change before implementing it.
2. Fork the repository, create a branch and keep changes within that scope.
3. Build with `./build.sh` and run the app's `--self-test`. No earbud access is required for routine CI.
4. Describe the problem, resulting behavior and validation in the pull request. Include a preview for visual changes and identify whether data is live or an example.

## Device changes

Model verification and readback are intentional boundaries. Do not add speculative write commands, remove model checks or present an unverified capability as supported. Document the command source, byte layout, tested hardware/firmware and restoration procedure. Do not add proprietary firmware or vendor images without a suitable redistribution license.

A new model needs its own capability/validation work; simply accepting its Bluetooth name is not enough. Use the device-support issue form to start a discussion.

## Code and documentation

Use the existing Swift/AppKit/SwiftUI structure; avoid adding dependencies for a small change. Respect macOS Reduce Motion/Reduce Transparency settings. Preserve unknown and disconnected states. Translation work should keep protocol IDs separate from UI strings.

Contributions are made under GPL-3.0-only, the project's license. Keep attribution for outside work and add original assets in editable/source form. No CLA is required.

## Community

Be respectful and specific. Focus criticism on behavior and code, not people. Do not post personal information, Bluetooth addresses or serial numbers. Report vulnerabilities privately through [Security Advisories](https://github.com/hikmetozcann/freebuds-kontrol/security/advisories/new), not public issues.
