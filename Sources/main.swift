// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = HeadsetModel()
    private var statusItem: NSStatusItem!
    private var window: NSPanel!
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let menuBar = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "FreeBuds Kontrol’den çık", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q").target = NSApp
        appMenuItem.submenu = appMenu
        menuBar.addItem(appMenuItem)
        NSApp.mainMenu = menuBar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "earbuds", accessibilityDescription: "FreeBuds Kontrol")!
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePanel)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "FreeBuds Kontrol"
        }
        model.onStatusChange = { [weak self] in self?.updateStatus() }
        window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: Theme.width, height: Theme.height), styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = "FreeBuds Kontrol"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        let hosting = NSHostingView(rootView: MainView(model: model))
        hosting.safeAreaRegions = []
        window.contentView = hosting
        window.setContentSize(NSSize(width: Theme.width, height: Theme.height))
        window.center()
        showPanel()
        model.start()
    }
    private func updateStatus() {
        let levels = [model.leftBattery, model.rightBattery].compactMap { $0 }
        statusItem?.button?.title = model.ready ? levels.min().map { " \($0)%" } ?? "" : ""
        statusItem?.button?.toolTip = model.ready ? "FreeBuds SE 4 ANC — Mac’e bağlı" : "FreeBuds Kontrol — bağlantı yok"
    }
    @objc func togglePanel() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "FreeBuds’u aç", action: #selector(showPanel), keyEquivalent: "").target = self
            menu.addItem(.separator())
            menu.addItem(withTitle: "Çıkış", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else if window.isVisible { window.orderOut(nil) }
        else { showPanel() }
    }
    @objc func showPanel() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showPanel(); return true }
    func applicationWillTerminate(_ notification: Notification) { model.stop() }
}

if CommandLine.arguments.contains("--self-test") {
    protocolChecks()
    exit(0)
}
if CommandLine.arguments.contains("--snapshot") || CommandLine.arguments.contains("--smoke-test") {
    let link = BluetoothLink()
    Task { @MainActor in
        do {
            if CommandLine.arguments.contains("--smoke-test") { try await liveSmoke(link) }
            else { printSnapshot(try await liveSnapshot(link)) }
            link.close(); exit(0)
        } catch { link.close(); fputs("ERROR: \(error.localizedDescription)\n", stderr); exit(1) }
    }
    RunLoop.main.run()
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
