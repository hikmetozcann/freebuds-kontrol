// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import Foundation

// Keys are the original Turkish strings. Translations live in
// Resources/<lang>.lproj/Localizable.strings (en, de, tr). A missing entry
// falls back to the key itself, so the UI never shows an empty string.
func L(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}
func L(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: L(key), arguments: arguments)
}
