// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import Foundation
import IOBluetooth

enum HeadsetError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case let .message(text) = self { return text }; return nil }
}

// All operations and IOBluetooth callbacks run on the main run loop.
// Only one request may be outstanding; the model serializes user changes and polling.
final class BluetoothLink: NSObject, IOBluetoothRFCOMMChannelDelegate {
    private var device: IOBluetoothDevice?
    private var channel: IOBluetoothRFCOMMChannel?
    private var decoder = Decoder()
    private var opening: CheckedContinuation<Void, Error>?
    private var connecting: CheckedContinuation<Void, Error>?
    private var openID = UUID()
    private var connectID = UUID()
    private var pending: (id: UUID, feature: Feature, continuation: CheckedContinuation<Packet, Error>)?
    private var verified = false
    var onPacket: ((Packet) -> Void)?
    var onDisconnect: (() -> Void)?
    var isOpen: Bool { channel?.isOpen() == true && device?.isConnected() == true }

    func findDevice() throws -> IOBluetoothDevice {
        let devices = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? [])
        let saved = UserDefaults.standard.string(forKey: "headsetAddress")
        if let saved, let found = devices.first(where: { $0.addressString == saved }) { return found }
        let matches = devices.filter { $0.name == "HUAWEI FreeBuds SE 4 ANC" }
        guard matches.count == 1, let found = matches.first else {
            throw HeadsetError.message(matches.isEmpty ? "FreeBuds SE 4 ANC’yi önce Mac’in Bluetooth ayarlarından eşleştirin." : "Birden fazla SE 4 ANC bulundu. Kullanacağınız kulaklığı Bluetooth ayarlarından bağlayın.")
        }
        return found
    }
    func connectToMac() async throws {
        let found = try findDevice()
        device = found
        if found.isConnected() { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connecting = continuation
            let id = UUID(); connectID = id
            let status = found.openConnection(self)
            if status != kIOReturnSuccess { finishConnect(.failure(HeadsetError.message("Mac bağlantısı kurulamadı (\(status)). iPhone’da kulaklığın bağlantısını kesip tekrar deneyin."))) }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 12_000_000_000)
                if self.connecting != nil, self.connectID == id { self.finishConnect(.failure(HeadsetError.message("Bağlantı zaman aşımına uğradı. Kulaklığı Mac’in Bluetooth ayarlarından bağlayın."))) }
            }
        }
    }
    @objc func connectionComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        finishConnect(status == kIOReturnSuccess ? .success(()) : .failure(HeadsetError.message("Mac bağlantısı kurulamadı (\(status)).")))
    }
    private func finishConnect(_ result: Result<Void, Error>) {
        let callback = connecting; connecting = nil; callback?.resume(with: result)
    }
    func open() async throws {
        if isOpen && verified { return }
        close()
        let found = try findDevice()
        device = found
        guard found.isConnected() else { throw HeadsetError.message("Kulaklık Mac’e bağlı değil. Bağlan düğmesini kullanın veya Bluetooth ayarlarını açın.") }
        let services = found.services as? [IOBluetoothSDPServiceRecord] ?? []
        guard let service = services.first(where: { $0.matchesUUID16(0x1101) }) else {
            throw HeadsetError.message("Kulaklığın kontrol servisi bulunamadı. Bluetooth bağlantısını yenileyin.")
        }
        var port: BluetoothRFCOMMChannelID = 0
        guard service.getRFCOMMChannelID(&port) == kIOReturnSuccess, port == 1 else {
            throw HeadsetError.message("Bu kulaklığın kontrol servisi desteklenmiyor.")
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            opening = continuation
            let id = UUID(); openID = id
            let status = found.openRFCOMMChannelAsync(&channel, withChannelID: port, delegate: self)
            if status != kIOReturnSuccess { finishOpen(.failure(HeadsetError.message("Kontrol bağlantısı açılamadı (\(status)). Diğer kulaklık yönetim uygulamasını kapatıp yenileyin."))) }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                if self.opening != nil, self.openID == id { self.finishOpen(.failure(HeadsetError.message("Kulaklık kontrol bağlantısına yanıt vermedi."))); self.close() }
            }
        }
        do {
            let info = try await read(.info)
            guard info.text(15) == "BTFT0026" else { throw HeadsetError.message("Bu uygulama yalnızca FreeBuds SE 4 ANC içindir.") }
            verified = true
            UserDefaults.standard.set(found.addressString, forKey: "headsetAddress")
        } catch { close(); throw error }
    }
    private func finishOpen(_ result: Result<Void, Error>) {
        let callback = opening; opening = nil; callback?.resume(with: result)
    }
    func close() {
        verified = false
        let old = channel; channel = nil
        old?.setDelegate(nil)
        old?.close()
        decoder = Decoder()
        if let request = pending { pending = nil; request.continuation.resume(throwing: HeadsetError.message("Kulaklığın bağlantısı kesildi.")) }
    }
    func rfcommChannelOpenComplete(_ channel: IOBluetoothRFCOMMChannel!, status: IOReturn) {
        finishOpen(status == kIOReturnSuccess ? .success(()) : .failure(HeadsetError.message("Kontrol bağlantısı kurulamadı (\(status)).")))
    }
    func rfcommChannelClosed(_ channel: IOBluetoothRFCOMMChannel!) {
        guard self.channel === channel else { return }
        self.channel = nil; verified = false
        if opening != nil { finishOpen(.failure(HeadsetError.message("Kulaklığın bağlantısı kesildi."))) }
        if let request = pending { pending = nil; request.continuation.resume(throwing: HeadsetError.message("Kulaklığın bağlantısı kesildi.")) }
        onDisconnect?()
    }
    func rfcommChannelData(_ channel: IOBluetoothRFCOMMChannel!, data pointer: UnsafeMutableRawPointer!, length: Int) {
        guard self.channel === channel, let pointer, (1...8192).contains(length) else { return }
        for packet in decoder.feed(Array(UnsafeBufferPointer(start: pointer.assumingMemoryBound(to: UInt8.self), count: length))) {
            onPacket?(packet)
            if let request = pending, request.feature.accepts(packet) {
                pending = nil; request.continuation.resume(returning: packet)
            }
        }
    }
    private func send(_ packet: Packet) throws {
        guard isOpen, let channel else { throw HeadsetError.message("Kulaklık bağlantısı kesildi. Yeniden bağlanın.") }
        var bytes = packet.encoded()
        let count = UInt16(bytes.count)
        let status = bytes.withUnsafeMutableBytes { channel.writeSync($0.baseAddress, length: count) }
        if status != kIOReturnSuccess { throw HeadsetError.message("Kulaklığa ulaşılamadı (\(status)). Yenileyip tekrar deneyin.") }
    }
    func read(_ feature: Feature) async throws -> Packet {
        guard pending == nil else { throw HeadsetError.message("Önceki kulaklık işlemi sürüyor.") }
        return try await withCheckedThrowingContinuation { continuation in
            let id = UUID()
            pending = (id, feature, continuation)
            do { try send(.read(feature.command, feature.keys)) }
            catch { pending = nil; continuation.resume(throwing: error); return }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                if let request = self.pending, request.id == id {
                    self.pending = nil
                    request.continuation.resume(throwing: HeadsetError.message("Kulaklık bu ayarı bildirmedi. Yenileyip tekrar deneyin."))
                }
            }
        }
    }
    func change(_ feature: Feature, fields: [UInt8: [UInt8]], matches: (Packet) -> Bool) async throws -> Packet {
        guard verified, let command = feature.writeCommand else { throw HeadsetError.message("Kulaklık modeli henüz doğrulanmadı." ) }
        try send(Packet(command, fields))
        for attempt in 0..<3 {
            try await Task.sleep(nanoseconds: feature == .latency ? 500_000_000 : 160_000_000)
            let packet = try await read(feature)
            if matches(packet) { return packet }
            if attempt == 2 { throw HeadsetError.message("Kulaklık değişikliği doğrulamadı; ekranda cihazdan okunan ayar gösteriliyor.") }
        }
        throw HeadsetError.message("Ayar doğrulanamadı.")
    }
}
