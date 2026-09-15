// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import Foundation

// Huawei SPP wire format and command meanings documented by OpenFreebuds.
// This implementation is original; references are recorded in README.md.
struct Packet: Equatable {
    let command: UInt16
    let fields: [UInt8: [UInt8]]
    init(_ command: UInt16, _ fields: [UInt8: [UInt8]] = [:]) { self.command = command; self.fields = fields }
    static func read(_ command: UInt16, _ keys: [UInt8]) -> Packet {
        Packet(command, Dictionary(uniqueKeysWithValues: keys.map { ($0, []) }))
    }
    func encoded() -> [UInt8] {
        var body = [UInt8(command >> 8), UInt8(command & 255)]
        for key in fields.keys.sorted() {
            let value = fields[key]!
            precondition(value.count <= 255)
            body += [key, UInt8(value.count)] + value
        }
        let length = body.count + 1
        var bytes = [UInt8(0x5a), UInt8(length >> 8), UInt8(length & 255), 0] + body
        let checksum = crc16(bytes)
        bytes += [UInt8(checksum >> 8), UInt8(checksum & 255)]
        return bytes
    }
    func byte(_ field: UInt8) -> Int? {
        guard let value = fields[field], value.count == 1 else { return nil }
        return Int(value[0])
    }
    func text(_ field: UInt8) -> String? {
        guard let bytes = fields[field], !bytes.isEmpty else { return nil }
        return String(bytes: bytes, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
    }
}
func crc16(_ bytes: [UInt8]) -> UInt16 {
    var value: UInt16 = 0
    for byte in bytes {
        value ^= UInt16(byte) << 8
        for _ in 0..<8 { value = value & 0x8000 != 0 ? (value << 1) ^ 0x1021 : value << 1 }
    }
    return value
}
struct Decoder {
    private var buffer: [UInt8] = []
    mutating func feed(_ bytes: [UInt8]) -> [Packet] {
        buffer += bytes
        var result: [Packet] = []
        while buffer.count >= 6 {
            guard buffer[0] == 0x5a else { buffer.removeFirst(); continue }
            let total = (Int(buffer[1]) << 8 | Int(buffer[2])) + 5
            guard (8...8192).contains(total), buffer[3] == 0 else { buffer.removeFirst(); continue }
            guard buffer.count >= total else { break }
            let frame = Array(buffer.prefix(total))
            guard crc16(Array(frame.dropLast(2))) == (UInt16(frame[total - 2]) << 8 | UInt16(frame[total - 1])) else {
                buffer.removeFirst(); continue
            }
            buffer.removeFirst(total)
            var fields: [UInt8: [UInt8]] = [:]
            var i = 6
            var valid = true
            while i < total - 2 {
                guard i + 2 <= total - 2 else { valid = false; break }
                let end = i + 2 + Int(frame[i + 1])
                guard end <= total - 2, fields[frame[i]] == nil else { valid = false; break }
                fields[frame[i]] = Array(frame[(i + 2)..<end]); i = end
            }
            if valid { result.append(Packet(UInt16(frame[4]) << 8 | UInt16(frame[5]), fields)) }
        }
        if buffer.count > 8192 { buffer.removeAll() }
        return result
    }
}
enum Feature: String, CaseIterable {
    case battery, info, anc, eq, doubleTap, tripleTap, longTap, noiseCycle, latency
    var command: UInt16 {
        switch self {
        case .battery: return 0x0108
        case .info: return 0x0107
        case .anc: return 0x2b2a
        case .eq: return 0x2b4a
        case .doubleTap: return 0x0120
        case .tripleTap: return 0x0126
        case .longTap: return 0x2b17
        case .noiseCycle: return 0x2b19
        case .latency: return 0x2b6c
        }
    }
    var writeCommand: UInt16? {
        switch self {
        case .anc: return 0x2b04
        case .eq: return 0x2b49
        case .doubleTap: return 0x011f
        case .tripleTap: return 0x0125
        case .longTap: return 0x2b16
        case .noiseCycle: return 0x2b18
        case .latency: return 0x2b6c
        default: return nil
        }
    }
    var keys: [UInt8] {
        switch self {
        case .info: return [3, 7, 10, 15]
        case .battery: return [1, 2, 3]
        case .anc, .noiseCycle: return [1, 2]
        case .latency: return [2]
        case .doubleTap: return [1, 2, 3, 4]
        default: return [1, 2, 3]
        }
    }
    func accepts(_ packet: Packet) -> Bool {
        guard packet.command == command else { return false }
        switch self {
        case .info: return packet.text(15) != nil
        case .anc: return packet.fields[1]?.count == 2
        case .eq, .latency: return packet.byte(2) != nil
        default: return packet.byte(1) != nil || packet.byte(2) != nil || (self == .battery && packet.fields[2]?.count == 3)
        }
    }
}
struct Option: Identifiable, Equatable {
    let id: Int
    let title: String
}
let tapOptions = [Option(id: 1, title: "Oynat / duraklat"), Option(id: 2, title: "Sonraki parça"), Option(id: 7, title: "Önceki parça"), Option(id: 0, title: "Sesli asistan"), Option(id: 255, title: "İşlem yapma")]
let holdOptions = [Option(id: 10, title: "Gürültü modunu değiştir"), Option(id: 18, title: "Sesi artır"), Option(id: 19, title: "Sesi azalt"), Option(id: 0, title: "Sesli asistan"), Option(id: 255, title: "İşlem yapma")]
let cycleOptions = [Option(id: 1, title: "Kapalı ↔ Engelleme"), Option(id: 2, title: "Kapalı / Engelleme / Farkındalık"), Option(id: 3, title: "Engelleme ↔ Farkındalık"), Option(id: 4, title: "Kapalı ↔ Farkındalık")]
let eqOptions = [Option(id: 1, title: "Varsayılan"), Option(id: 2, title: "Bas"), Option(id: 3, title: "Tiz"), Option(id: 9, title: "Vokaller")]
