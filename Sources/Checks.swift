// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import Foundation

func protocolChecks() {
    precondition(crc16(Array("123456789".utf8)) == 0x31c3)
    let a = Packet(0x2b2a, [1: [2, 1]])
    let b = Packet(0x0108, [1: [93], 2: [95, 93, 68]])
    for split in 0...a.encoded().count {
        var decoder = Decoder()
        let out = decoder.feed(Array(a.encoded().prefix(split))) + decoder.feed(Array(a.encoded().dropFirst(split)) + b.encoded())
        precondition(out == [a, b], "Frame split \(split) failed")
    }
    var bad = a.encoded(); bad[7] ^= 1
    var decoder = Decoder()
    precondition(decoder.feed([0, 1, 2] + bad + a.encoded()) == [a])
    var malformed = [UInt8](arrayLiteral: 0x5a, 0, 6, 0, 0x2b, 0x2a, 1, 8, 0)
    let sum = crc16(malformed); malformed += [UInt8(sum >> 8), UInt8(sum & 255)]
    var malformedDecoder = Decoder()
    precondition(malformedDecoder.feed(malformed).isEmpty)
    precondition(!Feature.latency.accepts(Packet(0x2b6c, [1: [0]])))
    precondition(Feature.latency.accepts(Packet(0x2b6c, [2: [0]])))
    precondition(!Feature.anc.accepts(Packet(0x2b2a, [1: [1]])))
    print("PASS: CRC vector, all fragment boundaries, concatenated frames, resynchronization, malformed TLV, ACK filtering")
}
@MainActor func liveSnapshot(_ link: BluetoothLink) async throws -> [Feature: Packet] {
    try await link.open()
    var data: [Feature: Packet] = [:]
    for feature in Feature.allCases { data[feature] = try await link.read(feature) }
    return data
}
func printSnapshot(_ data: [Feature: Packet]) {
    var json: [String: Any] = [:]
    for (feature, packet) in data {
        if feature == .info {
            json[feature.rawValue] = ["model": packet.text(15) ?? "", "firmware": packet.text(7) ?? "", "hardware": packet.text(3) ?? ""]
        } else {
            json[feature.rawValue] = Dictionary(uniqueKeysWithValues: packet.fields.map { (String($0.key), $0.value.map(Int.init)) })
        }
    }
    if let result = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]), let text = String(data: result, encoding: .utf8) { print(text) }
}
@MainActor func liveSmoke(_ link: BluetoothLink) async throws {
    let before = try await liveSnapshot(link)
    // Each test changes one reversible setting and restores its observed value
    // before proceeding. Restoration is also attempted on a failed verification.
    func test(_ label: String, _ feature: Feature, target: [UInt8: [UInt8]], restore: [UInt8: [UInt8]], field: UInt8, expected: [UInt8], original: [UInt8]) async throws {
        do {
            _ = try await link.change(feature, fields: target) { $0.fields[field] == expected }
            print("PASS: \(label) write and readback")
        } catch {
            do { _ = try await link.change(feature, fields: restore) { $0.fields[field] == original }; print("RESTORED: \(label)") }
            catch { print("RESTORE FAILED: \(label): \(error.localizedDescription)") }
            throw error
        }
        _ = try await link.change(feature, fields: restore) { $0.fields[field] == original }
        print("PASS: \(label) original setting restored")
    }
    if let original = before[.anc]?.fields[1], original.count == 2 {
        let mode = original[1]
        // Change ANC intensity while keeping ANC on whenever possible.
        let targetLevel: UInt8 = original[0] == 1 ? 2 : 1
        try await test("ANC intensity", .anc, target: [1: [1, targetLevel]], restore: [1: [mode, original[0]]], field: 1, expected: [targetLevel, 1], original: original)
    }
    if let original = before[.eq]?.fields[2], original.count == 1 {
        let value: UInt8 = original[0] == 2 ? 1 : 2
        try await test("EQ preset", .eq, target: [1: [value]], restore: [1: original], field: 2, expected: [value], original: original)
    }
    for feature in [Feature.doubleTap, .tripleTap, .longTap, .noiseCycle] {
        if let original = before[feature]?.fields[1], original.count == 1,
           let value = before[feature]?.fields[3]?.first(where: { $0 != original[0] && (feature != .noiseCycle || (1...4).contains($0)) }) {
            try await test(feature.rawValue, feature, target: [1: [value]], restore: [1: original], field: 1, expected: [value], original: original)
        }
    }
    if let original = before[.latency]?.fields[2], original.count == 1 {
        let value: UInt8 = original[0] == 1 ? 0 : 1
        try await test("Low latency", .latency, target: [1: [value]], restore: [1: original], field: 2, expected: [value], original: original)
    }
    let after = try await liveSnapshot(link)
    for feature in [Feature.anc, .eq, .doubleTap, .tripleTap, .longTap, .noiseCycle, .latency] {
        guard before[feature] == after[feature] else { throw HeadsetError.message("Final state differs for \(feature.rawValue)") }
    }
    print("PASS: all settings match initial snapshot; audio Bluetooth connection retained")
}
