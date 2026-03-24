import Foundation
import os.log

struct ThermalCollector {
    private static let logger = Logger(subsystem: "com.macvitals.app", category: "ThermalCollector")

    private var discoveredCPUKeys: [String] = []
    private var discoveredGPUKeys: [String] = []
    private var discoveredAllKeys: [String] = []
    private var hasDiscovered = false

    mutating func discoverKeys(using smc: SMCClient) {
        let allTempKeys = smc.discoverTemperatureKeys()

        discoveredCPUKeys = allTempKeys.filter { key in
            key.hasPrefix("Tc") || key.hasPrefix("TC") || key.hasPrefix("Tp")
        }
        discoveredGPUKeys = allTempKeys.filter { key in
            key.hasPrefix("Tg") || key.hasPrefix("TG")
        }
        discoveredAllKeys = allTempKeys

        hasDiscovered = true
        let cpuCount = discoveredCPUKeys.count
        let gpuCount = discoveredGPUKeys.count
        Self.logger.info("Discovered \(allTempKeys.count) temperature keys total, CPU: \(cpuCount), GPU: \(gpuCount)")
    }

    func collect(using smc: SMCClient) -> ThermalInfo {
        let cpuKeys = hasDiscovered ? discoveredCPUKeys : []
        let gpuKeys = hasDiscovered ? discoveredGPUKeys : []

        let cpuTemp = cpuKeys.lazy
            .compactMap { smc.readTemperature(key: $0) }
            .first { $0 > 0 && $0 < 150 }

        let gpuTemp = gpuKeys.lazy
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

        let allSensors: [SensorReading] = hasDiscovered ? discoveredAllKeys.compactMap { key in
            guard let temp = smc.readTemperature(key: key), temp > 0, temp < 150 else { return nil }
            return SensorReading(
                id: key,
                label: SensorLabelMap.label(for: key),
                value: temp,
                category: SensorLabelMap.category(for: key)
            )
        } : []

        return ThermalInfo(
            cpuTemperature: cpuTemp,
            gpuTemperature: gpuTemp,
            fans: fans,
            allSensors: allSensors
        )
    }
}
