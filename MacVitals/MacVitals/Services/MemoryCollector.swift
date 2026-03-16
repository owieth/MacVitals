import Foundation
import Darwin

struct MemoryCollector {
    func collect() -> MemoryInfo {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return .empty }

        let pageSize = UInt64(sysconf(_SC_PAGESIZE))
        let total = ProcessInfo.processInfo.physicalMemory
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let free = UInt64(stats.free_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let used = active + wired + compressed
        let available = free + inactive

        let usageRatio = Double(used) / Double(total)
        let pressure: MemoryPressure
        if usageRatio > 0.9 { pressure = .critical }
        else if usageRatio > 0.75 { pressure = .warning }
        else { pressure = .nominal }

        return MemoryInfo(
            total: total,
            used: used,
            active: active,
            wired: wired,
            compressed: compressed,
            available: available,
            pressure: pressure,
            topProcesses: []
        )
    }
}
