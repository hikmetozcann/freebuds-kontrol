// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import AppKit
import SwiftUI

enum Theme {
    static let width: CGFloat = 640
    static let height: CGFloat = 780
    static let accent = adaptive(light: 0x007AFF, dark: 0x64A9FF)
    static let battery = adaptive(light: 0x248A3D, dark: 0x32D74B)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x303136)
    static let background = adaptive(light: 0xF5F5F7, dark: 0x242529)
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: Double((hex >> 16) & 255) / 255,
                           green: Double((hex >> 8) & 255) / 255,
                           blue: Double(hex & 255) / 255, alpha: 1)
        })
    }
}

struct WindowMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// Set the window override explicitly so choosing System also clears a previous
// light/dark override; SwiftUI's nil preferredColorScheme can retain it in a panel.
struct WindowAppearance: NSViewRepresentable {
    let choice: String
    func makeNSView(context: Context) -> AppearanceHost { AppearanceHost() }
    func updateNSView(_ view: AppearanceHost, context: Context) {
        view.choice = choice
        DispatchQueue.main.async { view.applyAppearance() }
    }
}
final class AppearanceHost: NSView {
    var choice = "system"
    override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); applyAppearance() }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    func applyAppearance() {
        let name: NSAppearance.Name? = choice == "light" ? .aqua : choice == "dark" ? .darkAqua : nil
        if window?.appearance?.name != name {
            window?.appearance = name.flatMap { NSAppearance(named: $0) }
        }
    }
}

// The public macOS 26 AppKit class is available at runtime on this Mac even
// though its installed Xcode SDK predates it. Older systems use standard material.
struct NativeGlass: NSViewRepresentable {
    var radius: CGFloat = 22
    #if PREVIEW_RENDERER
    // Offscreen documentation renders cannot composite native window-server glass.
    private let reduceTransparency = true
    #else
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    #endif
    @Environment(\.colorScheme) private var scheme
    func makeNSView(context: Context) -> GlassHost { GlassHost(radius: radius) }
    func updateNSView(_ view: GlassHost, context: Context) {
        view.update(radius: radius, opaque: reduceTransparency, dark: scheme == .dark)
    }
}
final class GlassHost: NSView {
    private var effect: NSView?
    init(radius: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        if #available(macOS 26.0, *), let kind = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let glass = kind.init(frame: .zero)
            if glass.responds(to: NSSelectorFromString("setCornerRadius:")),
               glass.responds(to: NSSelectorFromString("setContentView:")) {
                glass.setValue(radius, forKey: "cornerRadius")
                glass.setValue(NSView(), forKey: "contentView")
                effect = glass
            }
        }
        if effect == nil {
            let material = NSVisualEffectView()
            material.material = .popover
            material.blendingMode = .withinWindow
            material.state = .active
            effect = material
        }
        if let effect {
            effect.frame = bounds
            effect.autoresizingMask = [.width, .height]
            addSubview(effect)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    func update(radius: CGFloat, opaque: Bool, dark: Bool) {
        let resolved = NSAppearance(named: dark ? .darkAqua : .aqua)
        appearance = resolved
        effect?.appearance = resolved
        layer?.cornerRadius = radius
        layer?.masksToBounds = true
        effect?.isHidden = opaque
        resolved?.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = opaque ? NSColor.controlBackgroundColor.cgColor : NSColor.clear.cgColor
        }
        if effect?.responds(to: NSSelectorFromString("setCornerRadius:")) == true {
            effect?.setValue(radius, forKey: "cornerRadius")
        }
    }
}

struct Surface<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    #if PREVIEW_RENDERER
    // Offscreen documentation renders cannot composite native window-server glass.
    private let reduceTransparency = true
    #else
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    #endif
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Theme.surface.opacity(reduceTransparency ? 1 : (scheme == .dark ? 0.82 : 0.76)), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(contrast == .increased ? 0.30 : 0.045), lineWidth: 0.5))
    }
}

struct QuietPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
struct CircleAction: View {
    let symbol: String
    let title: String
    let action: () -> Void
    @State private var hovered = false
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 14, weight: .medium))
                .frame(width: 32, height: 32)
                .background(Color.primary.opacity(hovered ? 0.10 : 0.045), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(QuietPressStyle())
        .onHover { hovered = $0 }
        .help(title).accessibilityLabel(title)
    }
}

struct BatteryGauge: View {
    let label: String
    let icon: String
    let level: Int?
    let charging: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var color: Color { (level ?? 100) <= 20 ? .orange : Theme.battery }
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().strokeBorder(Color.primary.opacity(0.09), lineWidth: 3)
                Circle().trim(from: 0, to: CGFloat(level ?? 0) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90)).padding(1.5)
                Image(systemName: charging ? "bolt.fill" : icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(level == nil ? Color.secondary : Color.primary)
            }.frame(width: 43, height: 43)
            VStack(alignment: .leading, spacing: 3) {
                Text(level.map { "\($0)%" } ?? "—")
                    .font(.system(size: 21, weight: .semibold, design: .rounded)).monospacedDigit()
                Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .center)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: level)
        .accessibilityElement(children: .ignore).accessibilityLabel(label)
        .accessibilityValue(level.map { "%\($0)\(charging ? ", şarj oluyor" : "")" } ?? "Pil bilgisi yok")
    }
}

struct ChoiceMenu: View {
    let title: String
    let value: Int?
    let options: [Option]
    let select: (Int) -> Void
    @State private var hovered = false
    private var selectedTitle: String { options.first(where: { $0.id == value })?.title ?? "Okunamadı" }
    var body: some View {
        Menu {
            ForEach(options) { option in
                Button { select(option.id) } label: {
                    if option.id == value { Label(option.title, systemImage: "checkmark") }
                    else { Text(option.title) }
                }
            }
        } label: {
            Text(selectedTitle).font(.system(size: 12, weight: .medium)).lineLimit(1)
        }.menuStyle(.borderlessButton).menuIndicator(.hidden).tint(.primary)
        .padding(.leading, 10).padding(.trailing, 25).frame(height: 29)
        .background(Color.primary.opacity(hovered ? 0.09 : 0.045), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(alignment: .trailing) {
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                .padding(.trailing, 10).allowsHitTesting(false)
        }
        .onHover { hovered = $0 }
        .accessibilityLabel(title).accessibilityValue(selectedTitle).help(selectedTitle)
    }
}
