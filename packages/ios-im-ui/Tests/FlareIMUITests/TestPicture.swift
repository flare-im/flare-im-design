#if os(macOS)
import AppKit

/// Pictures on this device that always load, for the hosted tests that click a picture to open it.
///
/// A picture that failed to load takes the next tap as a retry instead of opening (``ImageMessageView``), so a click
/// on a picture whose address cannot load races that load: an unresolvable host fails in milliseconds on a machine
/// that resolves it directly and only after seconds behind a proxy. These tests open a picture that has loaded.
enum TestPicture {
    private static var written: [Int: String] = [:]

    /// The `index`th picture: a small opaque PNG of its own in the temporary directory, written once per test run.
    /// Each index is a different file, so a gallery of several pictures has as many distinct sources.
    static func path(_ index: Int = 0) -> String {
        if let path = written[index] { return path }
        let size = 8
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                                      samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let shade = CGFloat(index % 8) / 8
        for x in 0..<size {
            for y in 0..<size { bitmap.setColor(NSColor(red: 0.2, green: 0.5, blue: shade, alpha: 1), atX: x, y: y) }
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flare-test-picture-\(getpid())-\(index).png")
        try! bitmap.representation(using: .png, properties: [:])!.write(to: url)
        written[index] = url.path
        return url.path
    }
}
#endif
