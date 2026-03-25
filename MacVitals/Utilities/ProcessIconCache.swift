import AppKit

@MainActor
final class ProcessIconCache {
    static let shared = ProcessIconCache()
    private let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 200
        return cache
    }()

    func icon(for process: ProcessSnapshot) -> NSImage {
        let key = process.executablePath as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let image = resolveIcon(path: process.executablePath)
        cache.setObject(image, forKey: key)
        return image
    }

    private func resolveIcon(path: String) -> NSImage {
        var url = URL(fileURLWithPath: path)
        while url.pathExtension != "app" && url.path != "/" {
            url = url.deletingLastPathComponent()
        }
        if url.pathExtension == "app" {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(forFile: path)
    }
}
