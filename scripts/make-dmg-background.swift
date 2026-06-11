import AppKit

// Renders the DMG window background (1x + 2x combined into a retina TIFF).
// Run from the repo root: swift scripts/make-dmg-background.swift

let size = NSSize(width: 560, height: 360)

func render(scale: CGFloat) -> URL {
    let pixels = NSSize(width: size.width * scale, height: size.height * scale)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(pixels.width), pixelsHigh: Int(pixels.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    NSColor(calibratedRed: 0.09, green: 0.094, blue: 0.11, alpha: 1).setFill()
    NSRect(origin: .zero, size: pixels).fill()

    // arrow midway between the two icon slots, nudged up toward icon centers
    let config = NSImage.SymbolConfiguration(pointSize: 52 * scale, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "arrow.right", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let tinted = NSImage(size: symbol.size, flipped: false) { rect in
            symbol.draw(in: rect)
            NSColor(white: 1, alpha: 0.28).set()
            rect.fill(using: .sourceAtop)
            return true
        }
        let arrowRect = NSRect(
            x: (pixels.width - tinted.size.width) / 2,
            y: pixels.height * 0.5 - tinted.size.height / 2,
            width: tinted.size.width,
            height: tinted.size.height
        )
        tinted.draw(in: arrowRect)
    }

    NSGraphicsContext.restoreGraphicsState()
    let url = URL(fileURLWithPath: "/tmp/dmg-bg-\(Int(scale))x.png")
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    return url
}

let one = render(scale: 1)
let two = render(scale: 2)

let tiffutil = Process()
tiffutil.executableURL = URL(fileURLWithPath: "/usr/bin/tiffutil")
tiffutil.arguments = ["-cathidpicheck", one.path, two.path, "-out", "Resources/DMGBackground.tiff"]
try! tiffutil.run()
tiffutil.waitUntilExit()
print(tiffutil.terminationStatus == 0 ? "wrote Resources/DMGBackground.tiff" : "tiffutil failed")
