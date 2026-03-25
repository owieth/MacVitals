import AppKit

@MainActor
final class ProcessIconCache {
    static let shared = ProcessIconCache()
    private var cache: [String: NSImage] = [:]

    func icon(for process: ProcessSnapshot) -> NSImage {
        if let cached = cache[process.executablePath] { return cached }
        let image = resolveIcon(path: process.executablePath)
        cache[process.executablePath] = image
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
