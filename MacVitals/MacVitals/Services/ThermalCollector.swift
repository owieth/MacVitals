import Foundation

struct ThermalCollector {
    private let cpuTempKeys = ["TC0P", "Tp09", "Tp01", "TC0p"]
    private let gpuTempKeys = ["TG0P", "Tg05", "Tg0P"]

    func collect(using smc: SMCClient) -> ThermalInfo {
        var cpuTemp: Double?
        for key in cpuTempKeys {
            if let temp = smc.readTemperature(key: key), temp > 0, temp < 150 {
                cpuTemp = temp
                break
            }
        }

        var gpuTemp: Double?
        for key in gpuTempKeys {
            if let temp = smc.readTemperature(key: key), temp > 0, temp < 150 {
                gpuTemp = temp
                break
            }
        }

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
