import Foundation
import os.log

struct ThermalCollector {
    private static let logger = Logger(subsystem: "com.macvitals.app", category: "ThermalCollector")

    // Intel + Apple Silicon CPU temperature keys
    private let cpuTempKeys = [
        "TC0P", "TC0p",             // Intel: CPU proximity
        "TC0c", "TC1c",             // Intel: per-core
        "Tp09", "Tp01", "Tp05",     // Apple Silicon: CPU die sensors
        "Tp0D", "Tp0A", "Tp0F",     // Apple Silicon: efficiency/performance cores
    ]

    // Intel + Apple Silicon GPU temperature keys
    private let gpuTempKeys = [
        "TG0P", "Tg0P",             // Intel: GPU proximity
        "Tg05", "Tg0D", "Tg0J",     // Apple Silicon: GPU die sensors
        "Tg1d",                      // Apple Silicon: additional GPU sensor
    ]

    func collect(using smc: SMCClient) -> ThermalInfo {
        let cpuTemp = cpuTempKeys.lazy
            .compactMap { smc.readTemperature(key: $0) }
            .first { $0 > 0 && $0 < 150 }

        if cpuTemp == nil {
            Self.logger.warning("No CPU temperature found from keys: \(self.cpuTempKeys)")
        }

        let gpuTemp = gpuTempKeys.lazy
            .compactMap { smc.readTemperature(key: $0) }
            .first { $0 > 0 && $0 < 150 }

        if gpuTemp == nil {
            Self.logger.debug("No GPU temperature found from keys: \(self.gpuTempKeys)")
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
