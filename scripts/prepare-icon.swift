import AppKit

// .icns files display their own alpha; macOS does not apply an app-icon mask.
// Apply the same rounded tile and transparent margin at every output size.
func validate(_ bitmap: NSBitmapImageRep) {
    let size = bitmap.pixelsWide
    precondition(bitmap.hasAlpha, "App icon must preserve transparency")
    for (x, y) in [(0, 0), (size - 1, 0), (0, size - 1), (size - 1, size - 1),
                   (size / 2, 0), (size / 10, size / 10)] {
        precondition(bitmap.colorAt(x: x, y: y)!.alphaComponent < 0.01,
                     "App icon corners and margins must be transparent")
    }
    for (x, y) in [(size / 2, size / 2), (size / 2, size / 4)] {
        precondition(bitmap.colorAt(x: x, y: y)!.alphaComponent > 0.99,
                     "App icon interior must remain opaque")
    }
}

let arguments = CommandLine.arguments
if arguments.count == 3 && arguments[1] == "--verify" {
    let directory = URL(fileURLWithPath: arguments[2])
    let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "png" }
    precondition(files.count == 10, "Expected all ten standard icon representations")
    for file in files {
        guard let bitmap = NSBitmapImageRep(data: try Data(contentsOf: file)) else { fatalError("Invalid PNG: \(file.path)") }
        validate(bitmap)
    }
    print("Verified rounded corners and alpha in all 10 packaged icon representations")
} else {
    precondition(arguments.count == 3, "Usage: swift prepare-icon.swift <source.png> <output.iconset>")
    guard let image = NSImage(contentsOfFile: arguments[1]),
          let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fatalError("Unable to load source icon")
    }
    let directory = URL(fileURLWithPath: arguments[2])
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for points in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let pixels = points * scale
            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
                let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
                fatalError("Unable to create icon bitmap")
            }
            let context = graphics.cgContext
            let canvas = CGRect(x: 0, y: 0, width: pixels, height: pixels)
            context.clear(canvas)
            let tile = canvas.insetBy(dx: CGFloat(pixels) * 0.08, dy: CGFloat(pixels) * 0.08)
            let radius = tile.width * 0.22
            context.addPath(CGPath(roundedRect: tile, cornerWidth: radius, cornerHeight: radius, transform: nil))
            context.clip()
            context.interpolationQuality = .high
            context.draw(source, in: tile)
            guard let data = bitmap.representation(using: .png, properties: [:]),
                  let encoded = NSBitmapImageRep(data: data) else { fatalError("Unable to encode icon") }
            validate(encoded)
            let suffix = scale == 2 ? "@2x" : ""
            try data.write(to: directory.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
        }
    }
    print("Prepared rounded app icon with transparent margins")
}
