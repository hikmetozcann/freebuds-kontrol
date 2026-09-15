// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import AppKit
import SwiftUI

/// Render the app's views offscreen using public example data, without Bluetooth.
@main struct PreviewRenderer {
    @MainActor static func main() throws {
        guard CommandLine.arguments.count == 3 else { fatalError("Usage: preview-renderer light|dark output.png") }
        let appearance = CommandLine.arguments[1]
        precondition(["light", "dark"].contains(appearance))
        let destination = URL(fileURLWithPath: CommandLine.arguments[2])
        UserDefaults.standard.register(defaults: ["appearance": appearance])
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        NSApp.appearance = NSAppearance(named: appearance == "dark" ? .darkAqua : .aqua)
        let model = HeadsetModel()
        model.ready = true
        model.message = "Arayüz önizlemesi — örnek veriler"
        model.packets = [
            .battery: Packet(0x0108, [2: [96, 94, 68], 3: [0, 0, 0]]),
            .anc: Packet(0x2b2a, [1: [2, 1]]),
            .eq: Packet(0x2b4a, [2: [1], 3: [1, 2, 3, 9]]),
            .latency: Packet(0x2b6c, [2: [0]])
        ]
        // Native glass depends on the window server and cannot be captured
        // reliably offscreen. Use the app's reduced-transparency appearance.
        let host = NSHostingView(rootView: MainView(model: model))
        host.safeAreaRegions = []
        let rect = NSRect(x: 0, y: 0, width: Theme.width, height: Theme.height)
        let window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: appearance == "dark" ? .darkAqua : .aqua)
        window.contentView = host
        host.frame = rect
        window.layoutIfNeeded()
        // No orderFront, screen capture, or connection to a physical device.
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        host.layoutSubtreeIfNeeded()
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("Cannot allocate preview") }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot render preview") }
        try png.write(to: destination)
        print(destination.lastPathComponent)
    }
}
