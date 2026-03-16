import Foundation
import IOKit

private let storageIOMainPort = kIOMainPortDefault

struct StorageCollector {
    private var previousReadBytes: UInt64 = 0
    private var previousWriteBytes: UInt64 = 0
    private var previousTimestamp: Date?

    mutating func collect() -> StorageInfo {
        var total: UInt64 = 0
        var free: UInt64 = 0
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") {
            total = (attrs[.systemSize] as? UInt64) ?? 0
            free = (attrs[.systemFreeSize] as? UInt64) ?? 0
        }

        var readBytes: UInt64 = 0
        var writeBytes: UInt64 = 0

        let matching = IOServiceMatching("IOBlockStorageDriver")
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(storageIOMainPort, matching, &iterator) == KERN_SUCCESS {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                if let props = serviceProperties(service) {
                    if let stats = props["Statistics"] as? [String: Any] {
                        readBytes += (stats["Bytes (Read)"] as? UInt64) ?? 0
                        writeBytes += (stats["Bytes (Write)"] as? UInt64) ?? 0
                    }
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }

        var readPerSec: UInt64 = 0
        var writePerSec: UInt64 = 0
        let now = Date()
        if let prev = previousTimestamp {
            let elapsed = now.timeIntervalSince(prev)
            if elapsed > 0, readBytes >= previousReadBytes, writeBytes >= previousWriteBytes {
                readPerSec = UInt64(Double(readBytes - previousReadBytes) / elapsed)
                writePerSec = UInt64(Double(writeBytes - previousWriteBytes) / elapsed)
            }
        }
        previousReadBytes = readBytes
        previousWriteBytes = writeBytes
        previousTimestamp = now

        return StorageInfo(
            total: total,
            used: total - free,
            free: free,
            readBytesPerSec: readPerSec,
            writeBytesPerSec: writePerSec
        )
    }

    private func serviceProperties(_ service: io_object_t) -> [String: Any]? {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(
            service, &props, kCFAllocatorDefault, 0
        ) == KERN_SUCCESS else { return nil }
        return props?.takeRetainedValue() as? [String: Any]
    }
}
