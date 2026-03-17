import Foundation

struct GPUInfo {
    let utilizationPercentage: Double
    let name: String

    static let empty = GPUInfo(utilizationPercentage: 0, name: "")
}
