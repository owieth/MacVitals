import Foundation

struct SystemSnapshot {
    let timestamp: Date
    let cpu: CPUInfo
    let memory: MemoryInfo
    let storage: StorageInfo
    let battery: BatteryInfo?
    let thermal: ThermalInfo
    let uptime: TimeInterval
}
