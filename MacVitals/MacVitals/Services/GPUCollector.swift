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
                    IOObjectRelease(service)
                    return GPUInfo(
                        utilizationPercentage: Double(utilization),
                        name: name
                    )
                }
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        return nil
    }
}
