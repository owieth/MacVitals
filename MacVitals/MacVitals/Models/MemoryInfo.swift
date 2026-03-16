import Foundation

enum MemoryPressure: String {
    case nominal = "Nominal"
    case warning = "Warning"
    case critical = "Critical"
}

struct MemoryInfo {
    let total: UInt64
    let used: UInt64
    let active: UInt64
    let wired: UInt64
    let compressed: UInt64
    let available: UInt64
    let pressure: MemoryPressure
    let topProcesses: [ProcessSnapshot]

    var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    static let empty = MemoryInfo(
        total: 0,
        used: 0,
        active: 0,
        wired: 0,
        compressed: 0,
        available: 0,
        pressure: .nominal,
        topProcesses: []
    )
}
