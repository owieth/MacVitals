import Foundation

struct GPUInfo {
    let utilizationPercentage: Double
    let name: String
    let vramTotal: UInt64?
    let vramUsed: UInt64?

    var vramPercentage: Double? {
        guard let total = vramTotal, let used = vramUsed, total > 0 else { return nil }
        return Double(used) / Double(total) * 100
    }

    static let empty = GPUInfo(
        utilizationPercentage: 0,
        name: "",
        vramTotal: nil,
        vramUsed: nil
    )
}
