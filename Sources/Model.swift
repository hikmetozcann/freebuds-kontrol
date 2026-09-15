// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import Foundation
import Combine

final class HeadsetModel: ObservableObject {
    let link = BluetoothLink()
    @Published var packets: [Feature: Packet] = [:]
    @Published var ready = false
    @Published var busy = false
    @Published var message: String?
    @Published var isError = false
    @Published var updatedAt: Date?
    @Published var tab = 0
    private var timer: Timer?
    var onStatusChange: (() -> Void)?

    init() {
        link.onPacket = { [weak self] packet in self?.receive(packet) }
        link.onDisconnect = { [weak self] in
            self?.ready = false; self?.packets = [:]
            self?.message = "Kulaklık Mac’e bağlı değil. Bağlanıp devam edebilirsiniz."
            self?.onStatusChange?()
        }
    }
    func start() {
        Task { @MainActor in await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            guard let self, !self.busy else { return }
            Task { @MainActor in await self.refresh(quiet: true) }
        }
    }
    func stop() { timer?.invalidate(); link.close() }
    private func receive(_ packet: Packet) {
        if let feature = Feature.allCases.first(where: { $0.accepts(packet) }) {
            packets[feature] = packet
            onStatusChange?()
        } else if packet.command == 0x0127, packet.fields[2]?.count == 3 {
            packets[.battery] = Packet(Feature.battery.command, packet.fields)
            onStatusChange?()
        }
    }
    @MainActor func refresh(quiet: Bool = false, connect: Bool = false) async {
        guard !busy else { return }
        busy = true
        let wasReady = ready
        defer { busy = false; onStatusChange?() }
        if !quiet { message = nil; isError = false }
        do {
            if connect { try await link.connectToMac() }
            try await link.open()
            ready = true
            for feature in Feature.allCases {
                do { receive(try await link.read(feature)) }
                catch {
                    packets.removeValue(forKey: feature)
                    if !link.isOpen { throw error }
                }
            }
            updatedAt = Date()
            if !quiet || !wasReady { message = "Ayarlar kulaklıktan okundu."; isError = false }
        } catch {
            ready = false; packets = [:]
            if !quiet || message == nil { message = error.localizedDescription; isError = true }
        }
    }
    var leftBattery: Int? { battery(at: 0) }
    var rightBattery: Int? { battery(at: 1) }
    var caseBattery: Int? { battery(at: 2) }
    private func battery(at index: Int) -> Int? {
        guard let bytes = packets[.battery]?.fields[2], bytes.count == 3, bytes[index] <= 100 else { return nil }
        return Int(bytes[index])
    }
    func charging(_ index: Int) -> Bool { packets[.battery]?.fields[3]?.indices.contains(index) == true && packets[.battery]?.fields[3]?[index] == 1 }
    var firmware: String { packets[.info]?.text(7) ?? "—" }
    var hardware: String { packets[.info]?.text(3) ?? "—" }
    var modelCode: String { packets[.info]?.text(15) ?? "—" }
    var ancMode: Int? { packets[.anc]?.fields[1].flatMap { $0.count == 2 ? Int($0[1]) : nil } }
    var ancLevel: Int? { packets[.anc]?.fields[1].flatMap { $0.count == 2 ? Int($0[0]) : nil } }
    var eq: Int? { packets[.eq]?.byte(2) }
    var latency: Bool? { packets[.latency]?.byte(2).flatMap { $0 <= 1 ? $0 == 1 : nil } }
    func value(_ feature: Feature, _ side: UInt8) -> Int? { packets[feature]?.byte(side) }
    func options(_ feature: Feature, side: UInt8 = 1) -> [Option] {
        let known: [Option]
        switch feature {
        case .eq: known = eqOptions
        case .longTap: known = holdOptions
        case .noiseCycle: known = cycleOptions
        default: known = tapOptions
        }
        let available = packets[feature]?.fields[3]?.map(Int.init) ?? []
        var result = available.isEmpty ? known : known.filter { available.contains($0.id) }
        let current = feature == .eq ? eq : value(feature, side)
        if let current, !result.contains(where: { $0.id == current }) {
            result.append(Option(id: current, title: known.first(where: { $0.id == current })?.title ?? "Cihaz ayarı (\(current))"))
        }
        return result
    }
    @MainActor private func perform(_ operation: () async throws -> Packet) async {
        guard !busy, ready, link.isOpen else { return }
        busy = true; message = "Kulaklıkta uygulanıyor…"; isError = false
        defer { busy = false; onStatusChange?() }
        do {
            receive(try await operation())
            updatedAt = Date(); message = "Kulaklıkta uygulandı ve doğrulandı."
        } catch {
            message = error.localizedDescription; isError = true
            if !link.isOpen { ready = false; packets = [:] }
        }
    }
    func setANC(mode: Int, level: Int? = nil) {
        guard (0...2).contains(mode), let oldMode = ancMode else { return }
        let desiredLevel = level ?? (mode == 1 && oldMode == 1 ? ancLevel : nil)
        guard desiredLevel == nil || (0...3).contains(desiredLevel!) else { return }
        Task { @MainActor in
            await perform {
                try await self.link.change(.anc, fields: [1: [UInt8(mode), UInt8(desiredLevel ?? (mode == 0 ? 0 : 255))]]) { packet in
                    guard let value = packet.fields[1], value.count == 2 else { return false }
                    return Int(value[1]) == mode && (desiredLevel == nil || Int(value[0]) == desiredLevel)
                }
            }
        }
    }
    func setEQ(_ id: Int) {
        guard options(.eq).contains(where: { $0.id == id }), eqOptions.contains(where: { $0.id == id }) else { return }
        Task { @MainActor in await perform { try await self.link.change(.eq, fields: [1: [UInt8(id)]]) { $0.byte(2) == id } } }
    }
    func setLatency(_ value: Bool) {
        guard latency != nil else { return }
        Task { @MainActor in await perform { try await self.link.change(.latency, fields: [1: [value ? 1 : 0]]) { $0.byte(2) == (value ? 1 : 0) } } }
    }
    func setGesture(_ feature: Feature, side: UInt8, value: Int) {
        guard [.doubleTap, .tripleTap, .longTap, .noiseCycle].contains(feature), [1, 2, 4].contains(side), (0...255).contains(value) else { return }
        if side == 4 {
            guard feature == .doubleTap, [0, 255].contains(value), self.value(feature, side) != nil else { return }
        } else {
            guard options(feature, side: side).contains(where: { $0.id == value }) else { return }
        }
        Task { @MainActor in await perform { try await self.link.change(feature, fields: [side: [UInt8(value)]]) { $0.byte(side) == value } } }
    }
}
