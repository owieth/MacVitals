import Foundation
import IOKit

struct GPUCollector {
    func collect() -> GPUInfo? {
        let matching = IOServiceMatching("IOAccelerator")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                if let perfStats = dict["PerformanceStatistics"] as? [String: Any] {
                    let utilization = perfStats["Device Utilization %"] as? Int
                        ?? perfStats["GPU Activity(%)"] as? Int
                        ?? 0
                    let name = dict["model"] as? String
                        ?? dict["IOClass"] as? String
                        ?? "GPU"

                    let vramUsed = vramValue(from: perfStats, keys: [
                        "vramUsedBytes",
                        "Alloc system memory",
                        "In use system memory",
                    ])

                    let vramTotal = vramTotalValue(dict: dict, perfStats: perfStats)

                    IOObjectRelease(service)
                    return GPUInfo(
                        utilizationPercentage: Double(utilization),
                        name: name,
                        vramTotal: vramTotal,
                        vramUsed: vramUsed
                    )
                }
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        return nil
    }

    private func vramValue(from stats: [String: Any], keys: [String]) -> UInt64? {
        for key in keys {
            if let val = stats[key] as? Int, val > 0 {
                return UInt64(val)
            }
            if let val = stats[key] as? UInt64, val > 0 {
                return val
            }
        }
        return nil
    }

    private func vramTotalValue(dict: [String: Any], perfStats: [String: Any]) -> UInt64? {
        if let mb = dict["VRAM,totalMB"] as? Int, mb > 0 {
            return UInt64(mb) * 1024 * 1024
        }
        if let val = perfStats["vramFreeBytes"] as? Int,
           let used = perfStats["vramUsedBytes"] as? Int, val > 0 {
            return UInt64(val + used)
        }
        return nil
    }
}
