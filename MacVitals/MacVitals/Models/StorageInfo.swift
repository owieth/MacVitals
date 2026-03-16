import Foundation

struct StorageInfo {
    let total: UInt64
    let used: UInt64
    let free: UInt64
    let readBytesPerSec: UInt64
    let writeBytesPerSec: UInt64

    var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    static let empty = StorageInfo(
        total: 0,
        used: 0,
        free: 0,
        readBytesPerSec: 0,
        writeBytesPerSec: 0
    )
}
