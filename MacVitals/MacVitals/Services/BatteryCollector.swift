import Foundation
import IOKit.ps

struct BatteryCollector {
    func collect() -> BatteryInfo? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let firstSource = sources.first,
              let info = IOPSGetPowerSourceDescription(
                  snapshot, firstSource as CFTypeRef
              )?.takeUnretainedValue() as? [String: Any]
        else { return nil }

        let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = info[kIOPSMaxCapacityKey] as? Int ?? 100
        let isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
        let powerSource = info[kIOPSPowerSourceStateKey] as? String ?? ""
        let isPluggedIn = powerSource == kIOPSACPowerValue
        let timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int
        let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int

        let level = maxCapacity > 0
            ? (Double(currentCapacity) / Double(maxCapacity)) * 100
            : 0

        var health: Double = 100
        var cycleCount = 0
        var temperature: Double?

        let matchingDict = IOServiceMatching("AppleSmartBattery")
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict)
        if service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(
                service, &props, kCFAllocatorDefault, 0
            ) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                cycleCount = dict["CycleCount"] as? Int ?? 0
                let designCap = dict["DesignCapacity"] as? Int ?? 0
                let maxCap = dict["MaxCapacity"] as? Int ?? 0
                if designCap > 0 {
                    health = (Double(maxCap) / Double(designCap)) * 100
                }
                if let temp = dict["Temperature"] as? Int {
                    temperature = Double(temp) / 100.0
                }
            }
            IOObjectRelease(service)
        }

        let timeRemaining: TimeInterval?
        if isCharging, let ttf = timeToFull, ttf > 0 {
            timeRemaining = TimeInterval(ttf * 60)
        } else if !isCharging, let tte = timeToEmpty, tte > 0 {
            timeRemaining = TimeInterval(tte * 60)
        } else {
            timeRemaining = nil
        }

        return BatteryInfo(
            level: level,
            health: min(health, 100),
            cycleCount: cycleCount,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            timeRemaining: timeRemaining,
            temperature: temperature
        )
    }
}
