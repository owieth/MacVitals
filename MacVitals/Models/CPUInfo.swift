import Foundation

struct CPUInfo {
    let totalUsage: Double
    let userUsage: Double
    let systemUsage: Double
    let coreUsages: [Double]
    let topProcesses: [ProcessSnapshot]

    static let empty = CPUInfo(
        totalUsage: 0,
        userUsage: 0,
        systemUsage: 0,
        coreUsages: [],
        topProcesses: []
    )
}

extension CPUInfo {
    func with(topProcesses: [ProcessSnapshot]) -> CPUInfo {
        CPUInfo(
            totalUsage: totalUsage,
            userUsage: userUsage,
            systemUsage: systemUsage,
            coreUsages: coreUsages,
            topProcesses: topProcesses
        )
    }
}
