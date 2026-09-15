// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import AppKit
let directory = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
for (pixels, filename) in [(16,"icon_16x16.png"),(32,"icon_16x16@2x.png"),(32,"icon_32x32.png"),(64,"icon_32x32@2x.png"),(128,"icon_128x128.png"),(256,"icon_128x128@2x.png"),(256,"icon_256x256.png"),(512,"icon_256x256@2x.png"),(512,"icon_512x512.png"),(1024,"icon_512x512@2x.png")] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = CGFloat(pixels) / 512
    let transform = NSAffineTransform(); transform.scale(by: scale); transform.concat()
    NSColor(calibratedRed: 0.91, green: 0.94, blue: 0.97, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 28, y: 28, width: 456, height: 456), xRadius: 103, yRadius: 103).fill()
    for (cx, angle) in [(CGFloat(181),CGFloat(15)), (CGFloat(331),CGFloat(-15))] {
        NSGraphicsContext.saveGraphicsState()
        let t = NSAffineTransform(); t.translateX(by: cx, yBy: 286); t.rotate(byDegrees: angle); t.concat()
        NSColor(calibratedRed: 0.16, green: 0.23, blue: 0.30, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: -22, y: -133, width: 44, height: 145), xRadius: 22, yRadius: 22).fill()
        NSBezierPath(ovalIn: NSRect(x: -48, y: -17, width: 96, height: 100)).fill()
        NSColor(calibratedRed: 0.43, green: 0.51, blue: 0.58, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: -23, y: 28, width: 46, height: 21)).fill()
        NSColor(calibratedRed: 0.83, green: 0.18, blue: 0.26, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: -12, y: -118, width: 24, height: 7), xRadius: 3.5, yRadius: 3.5).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: directory).appendingPathComponent(filename))
}
