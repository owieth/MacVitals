import Foundation

struct ThermalCollector {
    private let cpuTempKeys = ["TC0P", "Tp09", "Tp01", "TC0p"]
    private let gpuTempKeys = ["TG0P", "Tg05", "Tg0P"]

    func collect(using smc: SMCClient) -> ThermalInfo {
        let cpuTemp = cpuTempKeys.lazy
            .compactMap { smc.readTemperature(key: $0) }
            .first { $0 > 0 && $0 < 150 }

        let gpuTemp = gpuTempKeys.lazy
            .compactMap { smc.readTemperature(key: $0) }
            .first { $0 > 0 && $0 < 150 }

        let fanCount = smc.readFanCount()
        var fans: [FanInfo] = []
        for i in 0..<fanCount {
            if let current = smc.readFanSpeed(index: i) {
                let min = smc.readFanMin(index: i) ?? 0
                let max = smc.readFanMax(index: i) ?? 0
                fans.append(FanInfo(id: i, currentRPM: current, minRPM: min, maxRPM: max))
            }
        }

        return ThermalInfo(cpuTemperature: cpuTemp, gpuTemperature: gpuTemp, fans: fans)
    }
}
