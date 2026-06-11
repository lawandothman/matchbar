import AppKit

// Renders AppIcon.iconset and compiles Resources/AppIcon.icns.
// Run from the repo root: swift scripts/make-icon.swift

func renderIcon(pixels: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: pixels, height: pixels))
    image.lockFocus()

    // Apple icon grid: 824pt squircle centered on a 1024pt canvas, radius ~185pt
    let inset = pixels * 100.0 / 1024.0
    let radius = pixels * 185.0 / 1024.0
    let rect = NSRect(x: inset, y: inset, width: pixels - 2 * inset, height: pixels - 2 * inset)
    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.10, alpha: 1).setFill()
    squircle.fill()

    let config = NSImage.SymbolConfiguration(pointSize: pixels * 0.42, weight: .regular)
    if let symbol = NSImage(systemSymbolName: "soccerball", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let white = NSImage(size: symbol.size, flipped: false) { drawRect in
            symbol.draw(in: drawRect)
            NSColor.white.set()
            drawRect.fill(using: .sourceAtop)
            return true
        }
        let ballRect = NSRect(
            x: (pixels - white.size.width) / 2,
            y: (pixels - white.size.height) / 2,
            width: white.size.width,
            height: white.size.height
        )
        white.draw(in: ballRect)
    }

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, pixels: Int, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

let iconset = URL(fileURLWithPath: "AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let suffix = scale == 2 ? "@2x" : ""
        let url = iconset.appendingPathComponent("icon_\(size)x\(size)\(suffix).png")
        writePNG(renderIcon(pixels: CGFloat(pixels)), pixels: pixels, to: url)
    }
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", "AppIcon.iconset", "-o", "Resources/AppIcon.icns"]
try! iconutil.run()
iconutil.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
print(iconutil.terminationStatus == 0 ? "wrote Resources/AppIcon.icns" : "iconutil failed")
