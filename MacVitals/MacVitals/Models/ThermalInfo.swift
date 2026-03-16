import Foundation

struct FanInfo: Identifiable {
    let id: Int
    let currentRPM: Int
    let minRPM: Int
    let maxRPM: Int
}

struct ThermalInfo {
    let cpuTemperature: Double?
    let gpuTemperature: Double?
    let fans: [FanInfo]

    static let empty = ThermalInfo(
        cpuTemperature: nil,
        gpuTemperature: nil,
        fans: []
    )
}
