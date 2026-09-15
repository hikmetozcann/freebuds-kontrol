// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import SwiftUI
import AppKit

struct MainView: View {
    @ObservedObject var model: HeadsetModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if PREVIEW_RENDERER
    // Offscreen documentation renders cannot composite native window-server glass.
    private let reduceTransparency = true
    #else
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    #endif
    @AppStorage("appearance") private var appearance = "system"
    @Namespace private var navigation
    private let tabs = [("Ses", "waveform"), ("Dokunmalar", "hand.tap"), ("Cihaz", "info.circle")]
    private var animation: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.2) }
    var body: some View {
        VStack(spacing: 0) {
            chrome
            header.padding(.horizontal, 38)
            batteries.padding(.horizontal, 27).padding(.top, 13).padding(.bottom, 22)
            tabBar.padding(.horizontal, 104).padding(.bottom, 18)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !model.ready { disconnected }
                    if model.tab == 0 { sound }
                    else if model.tab == 1 { gestures }
                    else { device }
                }.padding(.horizontal, 26).padding(.top, 2).padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }.id(model.tab).scrollIndicators(.automatic)
            footer
        }
        .font(.system(size: 13))
        .tint(Theme.accent)
        .frame(width: Theme.width, height: Theme.height)
        .background {
            if reduceTransparency { Theme.background }
            else {
                WindowMaterial()
                Theme.background.opacity(scheme == .dark ? 0.42 : 0.35)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.white.opacity(scheme == .dark ? 0.10 : 0.60), lineWidth: 0.5))
        .background(WindowAppearance(choice: appearance).allowsHitTesting(false))
    }
    private var chrome: some View {
        HStack {
            Text("FreeBuds Kontrol").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary).padding(.leading, 26)
            Spacer()
            Menu {
                Picker("Görünüm", selection: $appearance) {
                    Text("Sistem").tag("system")
                    Text("Açık").tag("light")
                    Text("Koyu").tag("dark")
                }
                Button("Bluetooth ayarlarını aç", action: openBluetoothSettings)
                Divider()
                Button("Çıkış") { NSApp.terminate(nil) }.keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 16, weight: .medium)).frame(width: 28, height: 24)
            }.menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .help("Uygulama seçenekleri").accessibilityLabel("Uygulama seçenekleri")
        }.padding(.horizontal, 20).frame(height: 36)
    }
    private var header: some View {
        HStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 5) {
                Text("FreeBuds").font(.system(size: 34, weight: .semibold)).tracking(-1.0)
                Text("SE 4 ANC").font(.system(size: 16)).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Circle().fill(model.ready ? Theme.battery : Color.secondary).frame(width: 5, height: 5)
                    Text(model.ready ? "Mac’e bağlı" : (model.busy ? "Bağlanıyor" : "Bağlantı yok"))
                        .font(.system(size: 11, weight: .medium))
                }.padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.primary.opacity(0.045), in: Capsule()).padding(.top, 7)
            }
            Spacer(minLength: 0)
            EarbudsArtwork()
        }.frame(height: 138)
    }
    private var batteries: some View {
        HStack(spacing: 6) {
            BatteryGauge(label: "Sol kulaklık", icon: "earbud.left", level: model.leftBattery, charging: model.charging(0))
            BatteryGauge(label: "Sağ kulaklık", icon: "earbud.right", level: model.rightBattery, charging: model.charging(1))
            BatteryGauge(label: "Şarj kutusu", icon: "earbuds.case", level: model.caseBattery, charging: model.charging(2))
        }.frame(height: 52)
    }
    private var tabBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(animation) { model.tab = index }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: tabs[index].1).font(.system(size: 12, weight: .semibold))
                        Text(tabs[index].0).font(.system(size: 12, weight: .semibold))
                    }.frame(maxWidth: .infinity).frame(height: 36)
                    .foregroundStyle(model.tab == index ? Color.primary : Color.secondary)
                    .background {
                        if model.tab == index {
                            Capsule().fill(scheme == .dark ? .white.opacity(0.16) : .white.opacity(0.85))
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                                .matchedGeometryEffect(id: "selected", in: navigation)
                        }
                    }.contentShape(Capsule())
                }.buttonStyle(QuietPressStyle())
                .accessibilityLabel(tabs[index].0)
                .accessibilityAddTraits(model.tab == index ? .isSelected : [])
                .accessibilityValue(model.tab == index ? "Seçili" : "Seçili değil")
            }
        }.padding(4).background(NativeGlass(radius: 23).id(scheme).allowsHitTesting(false))
    }
    private var sound: some View {
        VStack(spacing: 16) {
            Surface {
                VStack(alignment: .leading, spacing: 15) {
                    sectionHeader("Gürültü kontrolü", icon: "waveform.badge.minus")
                    HStack(spacing: 9) {
                        modeButton(0, "Kapalı", "speaker.wave.2")
                        modeButton(1, "Engelleme", "waveform.badge.minus")
                        modeButton(2, "Farkındalık", "ear.badge.waveform")
                    }
                    if model.ancMode == 1 {
                        HStack {
                            Text("Seviye").font(.system(size: 12)).foregroundStyle(.secondary)
                            Spacer()
                            intensityControl.frame(width: 285)
                        }
                    }
                    if model.ready && model.ancMode == nil { unavailable }
                }.animation(animation, value: model.ancMode)
            }
            Surface {
                VStack(spacing: 15) {
                    HStack(spacing: 12) {
                        settingIcon("slider.horizontal.3")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ses profili").fontWeight(.medium)
                            Text(eqDescription).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 12)
                        ChoiceMenu(title: "Ses profili", value: model.eq, options: model.options(.eq), select: model.setEQ)
                            .frame(width: 134).disabled(!canEdit(.eq))
                    }.frame(minHeight: 40)
                    Divider().opacity(0.6)
                    HStack(spacing: 12) {
                        settingIcon("bolt")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Düşük gecikme").fontWeight(.medium)
                            Text("Kulaklığın gecikme tercihi.").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if model.latency != nil {
                            Toggle("Düşük gecikme", isOn: Binding(get: { model.latency ?? false }, set: { model.setLatency($0) }))
                                .labelsHidden().toggleStyle(.switch).controlSize(.small).disabled(!canEdit(.latency))
                        } else { Text("—").foregroundStyle(.secondary) }
                    }.frame(minHeight: 38)
                }
            }
        }
    }
    private func modeButton(_ value: Int, _ title: String, _ symbol: String) -> some View {
        let selected = model.ancMode == value
        return Button { model.setANC(mode: value) } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 23, weight: .regular)).frame(height: 26)
                Text(title).font(.system(size: 12, weight: selected ? .semibold : .medium))
            }.frame(maxWidth: .infinity).frame(height: 76)
                .foregroundStyle(selected ? Theme.accent : Color.secondary)
                .background(selected ? Theme.accent.opacity(scheme == .dark ? 0.16 : 0.09) : Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 11)).foregroundStyle(Theme.accent).padding(7)
                    }
                }.contentShape(RoundedRectangle(cornerRadius: 15))
        }.buttonStyle(QuietPressStyle()).disabled(!canEdit(.anc))
        .accessibilityLabel(title).accessibilityValue(selected ? "Seçili" : "Seçili değil")
    }
    private var intensityOptions: [Option] {
        var items = [Option(id: 1, title: "Hafif"), Option(id: 0, title: "Dengeli"), Option(id: 2, title: "Güçlü")]
        if let level = model.ancLevel, !items.contains(where: { $0.id == level }) {
            items.append(Option(id: level, title: level == 3 ? "Otomatik" : "Cihaz ayarı"))
        }
        return items
    }
    private var intensityControl: some View {
        HStack(spacing: 2) {
            ForEach(intensityOptions) { option in
                Button { model.setANC(mode: 1, level: option.id) } label: {
                    Text(option.title).font(.system(size: 11, weight: model.ancLevel == option.id ? .semibold : .regular))
                        .frame(maxWidth: .infinity).frame(height: 24)
                        .foregroundStyle(model.ancLevel == option.id ? Color.primary : Color.secondary)
                        .background {
                            if model.ancLevel == option.id {
                                Capsule().fill(scheme == .dark ? .white.opacity(0.15) : .white)
                                    .shadow(color: .black.opacity(0.07), radius: 2, y: 1)
                            }
                        }.contentShape(Capsule())
                }.buttonStyle(QuietPressStyle()).disabled(!canEdit(.anc) || !(0...3).contains(option.id))
                    .accessibilityLabel("Engelleme seviyesi: \(option.title)")
                    .accessibilityValue(model.ancLevel == option.id ? "Seçili" : "Seçili değil")
            }
        }.padding(3).background(Color.primary.opacity(0.045), in: Capsule())
    }
    private var eqDescription: String {
        switch model.eq {
        case 1: return "Doğal ve dengeli."
        case 2: return "Bas frekansları öne çıkar."
        case 3: return "Tiz frekansları öne çıkar."
        case 9: return "Konuşma ve vokaller öne çıkar."
        default: return "Kulaklıktan okunamadı."
        }
    }
    private var gestures: some View {
        VStack(spacing: 16) {
            Surface {
                VStack(alignment: .leading, spacing: 17) {
                    gestureGroup("İki kez dokun", .doubleTap, icon: "hand.tap")
                    Divider().opacity(0.6)
                    gestureGroup("Üç kez dokun", .tripleTap, icon: "hand.tap")
                    Divider().opacity(0.6)
                    gestureGroup("Basılı tut", .longTap, icon: "hand.point.up.left")
                }
            }
            if model.value(.longTap, 1) == 10 || model.value(.longTap, 2) == 10 {
                Surface {
                    VStack(alignment: .leading, spacing: 13) {
                        sectionHeader("Gürültü modu geçişi", icon: "arrow.triangle.2.circlepath")
                        Text("Basılı tutunca geçiş yapılacak modlar.").font(.system(size: 11)).foregroundStyle(.secondary)
                        if model.value(.longTap, 1) == 10 { cycleRow("Sol", 1) }
                        if model.value(.longTap, 2) == 10 { cycleRow("Sağ", 2) }
                    }
                }
            }
            if model.value(.doubleTap, 4) != nil {
                Surface {
                    HStack(spacing: 12) {
                        settingIcon("phone")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Aramayı yanıtla / bitir").fontWeight(.medium)
                            Text("İki kez dokunarak.").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("İki dokunuşla aramayı yanıtla / bitir", isOn: Binding(get: { model.value(.doubleTap, 4) == 0 }, set: { model.setGesture(.doubleTap, side: 4, value: $0 ? 0 : 255) }))
                            .labelsHidden().toggleStyle(.switch).controlSize(.small).disabled(!canEdit(.doubleTap))
                    }
                }
            }
        }
    }
    private func gestureGroup(_ title: String, _ feature: Feature, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeader(title, icon: icon)
            HStack(spacing: 20) {
                gestureCell("Sol", feature, 1)
                gestureCell("Sağ", feature, 2)
            }
        }
    }
    private func gestureCell(_ label: String, _ feature: Feature, _ side: UInt8) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: side == 1 ? "earbud.left" : "earbud.right")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            gesturePicker(label, feature, side)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func cycleRow(_ label: String, _ side: UInt8) -> some View {
        HStack {
            Label(label, systemImage: side == 1 ? "earbud.left" : "earbud.right")
                .foregroundStyle(.secondary).frame(width: 65, alignment: .leading)
            gesturePicker(label, .noiseCycle, side)
        }
    }
    private func gesturePicker(_ label: String, _ feature: Feature, _ side: UInt8) -> some View {
        ChoiceMenu(title: "\(label) \(gestureName(feature))", value: model.value(feature, side), options: model.options(feature, side: side)) {
            model.setGesture(feature, side: side, value: $0)
        }.frame(maxWidth: .infinity)
            .disabled(!canEdit(feature) || model.value(feature, side) == nil)
    }
    private func gestureName(_ feature: Feature) -> String {
        switch feature { case .doubleTap: return "iki dokunma"; case .tripleTap: return "üç dokunma"; case .longTap: return "basılı tutma"; default: return "gürültü geçişi" }
    }
    private var device: some View {
        VStack(spacing: 16) {
            Surface {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Kulaklık bilgileri", icon: "earbuds")
                    infoRow("Model", "FreeBuds SE 4 ANC")
                    Divider().opacity(0.6)
                    infoRow("Yazılım sürümü", model.firmware)
                    infoRow("Donanım sürümü", model.hardware)
                    infoRow("Model kodu", model.modelCode)
                }
            }
            Surface {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Bağlantı", icon: "antenna.radiowaves.left.and.right")
                    Text("Ayarları değiştirmek için kulaklığın Mac’e bağlı olması gerekir. Başka bir cihaza geçtiğinde panel bağlantıyı bekler.")
                        .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Bluetooth ayarlarını aç", action: openBluetoothSettings).controlSize(.large)
                        Spacer()
                        if !model.ready { connectButton }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("FreeBuds Kontrol \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Development")").font(.system(size: 11, weight: .medium))
                Text("SE 4 ANC için bağımsız Mac uygulaması. Kulaklık güncellemeleri için HUAWEI Audio Connect’i kullanın.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 15) {
                    Link("OpenFreebuds", destination: URL(string: "https://github.com/melianmiko/OpenFreebuds")!)
                    Link("Kaynak kodu · GPL-3.0", destination: URL(string: "https://github.com/hikmetozcann/freebuds-kontrol")!)
                }.font(.system(size: 11)).padding(.top, 3)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 5)
        }
    }
    private var disconnected: some View {
        Surface {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "antenna.radiowaves.left.and.right.slash").font(.system(size: 25)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.busy ? "Kulaklık aranıyor…" : "Kulaklığını Mac’e bağla").font(.system(size: 15, weight: .semibold))
                    Text("Başka bir cihaza bağlıysa önce o bağlantıyı kesmeniz gerekebilir.").font(.system(size: 12)).foregroundStyle(.secondary)
                    HStack { connectButton; Button("Bluetooth ayarları", action: openBluetoothSettings).buttonStyle(.link) }
                }
            }
        }
    }
    private var connectButton: some View {
        Button("Mac’e bağlan") { Task { @MainActor in await model.refresh(connect: true) } }
            .controlSize(.large).disabled(model.busy)
    }
    private var footer: some View {
        HStack(spacing: 10) {
            ZStack {
                if model.busy { ProgressView().controlSize(.small).scaleEffect(0.7) }
                else {
                    Image(systemName: model.isError ? "exclamationmark.circle" : model.ready ? "checkmark.circle" : "circle.dotted")
                        .font(.system(size: 14)).foregroundStyle(model.isError ? Color.orange : Color.secondary)
                }
            }.frame(width: 17, height: 17)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.busy ? "Kulaklıkla iletişim kuruluyor…" : (model.message ?? "Ayarlar kulaklıktan okunuyor."))
                    .font(.system(size: 11)).foregroundStyle(model.isError ? Color.primary : Color.secondary)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                if let date = model.updatedAt, model.ready {
                    Text("Son okuma \(date.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 10)).foregroundStyle(.tertiary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            CircleAction(symbol: "arrow.clockwise", title: "Ayarları yenile") {
                Task { @MainActor in await model.refresh() }
            }.disabled(model.busy)
        }.padding(.horizontal, 30).padding(.bottom, 12).padding(.top, 8).frame(minHeight: 56)
    }
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary).frame(width: 18)
            Text(title).font(.system(size: 14, weight: .semibold))
        }
    }
    private func settingIcon(_ symbol: String) -> some View {
        Image(systemName: symbol).font(.system(size: 18, weight: .regular)).foregroundStyle(.secondary)
            .frame(width: 34, height: 34).background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
    }
    private var unavailable: some View { Text("Bu ayar okunamadı. Yenileyip tekrar deneyin.").font(.system(size: 12)).foregroundStyle(.secondary) }
    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value).textSelection(.enabled) }.font(.system(size: 12))
    }
    private func canEdit(_ feature: Feature) -> Bool { model.ready && !model.busy && model.packets[feature] != nil }
}
func openBluetoothSettings() {
    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings")!)
}
