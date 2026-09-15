# Security policy

The latest published release is the supported version. This volunteer project does not promise a response SLA.

Report a suspected vulnerability using [GitHub private vulnerability reporting](https://github.com/hikmetozcann/freebuds-kontrol/security/advisories/new). Include the affected version, a minimal reproduction and expected impact. Do not open a public issue with an exploit or unredacted device identifiers.

Relevant areas include Bluetooth packet parsing, model verification, command restrictions, release integrity and accidental disclosure in diagnostics. Device compatibility problems without a security impact belong in ordinary issues.

The app communicates with a paired Bluetooth accessory and is not sandboxed. Releases are ad hoc signed, not Developer ID signed or notarized. SHA-256 files check integrity against the release assets; they are not an independent publisher signature. Review the source and provenance before trusting a build.
