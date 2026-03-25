import Testing
@testable import MacVitals

struct MacVitalsTests {
    // MARK: - Formatter Tests

    @Test func formatPercentage() async throws {
        #expect(Formatters.percentage(62.4) == "62%")
        #expect(Formatters.percentage(0) == "0%")
        #expect(Formatters.percentage(100) == "100%")
    }

    @Test func formatPercentageEdgeCases() async throws {
        #expect(Formatters.percentage(-1) == "-1%")
        #expect(Formatters.percentage(999.9) == "1000%")
        #expect(Formatters.percentage(0.4) == "0%")
        #expect(Formatters.percentage(0.5) == "0%")
    }

    @Test func formatUptime() async throws {
        #expect(Formatters.uptime(3600) == "1h 0m")
        #expect(Formatters.uptime(90000) == "1d 1h 0m")
        #expect(Formatters.uptime(300) == "5m")
    }

    @Test func formatUptimeEdgeCases() async throws {
        #expect(Formatters.uptime(0) == "0m")
        #expect(Formatters.uptime(59) == "0m")
        #expect(Formatters.uptime(60) == "1m")
        #expect(Formatters.uptime(86400) == "1d 0h 0m")
    }

    @Test func formatTemperatureCelsius() async throws {
        #expect(Formatters.temperature(62.0, unit: .celsius) == "62°C")
    }

    @Test func formatTemperatureFahrenheit() async throws {
        #expect(Formatters.temperature(0.0, unit: .fahrenheit) == "32°F")
        #expect(Formatters.temperature(100.0, unit: .fahrenheit) == "212°F")
    }

    @Test func formatTemperatureEdgeCases() async throws {
        #expect(Formatters.temperature(-40.0, unit: .celsius) == "-40°C")
        #expect(Formatters.temperature(-40.0, unit: .fahrenheit) == "-40°F")
    }

    @Test func formatRPM() async throws {
        #expect(Formatters.rpm(0) == "0 RPM")
        #expect(Formatters.rpm(1500) == "1500 RPM")
    }

    // MARK: - Model Tests

    @Test func memoryUsagePercentage() async throws {
        let info = MemoryInfo(
            total: 16_000_000_000,
            used: 8_000_000_000,
            active: 4_000_000_000,
            wired: 2_000_000_000,
            compressed: 1_000_000_000,
            available: 8_000_000_000,
            pressure: .nominal,
            topProcesses: []
        )
        #expect(info.usagePercentage == 50.0)
    }

    @Test func memoryUsagePercentageZeroTotal() async throws {
        let info = MemoryInfo(
            total: 0,
            used: 0,
            active: 0,
            wired: 0,
            compressed: 0,
            available: 0,
            pressure: .nominal,
            topProcesses: []
        )
        #expect(info.usagePercentage == 0.0)
    }

    @Test func storageUsagePercentage() async throws {
        let info = StorageInfo(
            total: 500_000_000_000,
            used: 250_000_000_000,
            free: 250_000_000_000,
            readBytesPerSec: 0,
            writeBytesPerSec: 0
        )
        #expect(info.usagePercentage == 50.0)
    }

    @Test func storageUsagePercentageZeroTotal() async throws {
        let info = StorageInfo(
            total: 0,
            used: 0,
            free: 0,
            readBytesPerSec: 0,
            writeBytesPerSec: 0
        )
        #expect(info.usagePercentage == 0.0)
    }

    @Test func cpuInfoEmpty() async throws {
        let empty = CPUInfo.empty
        #expect(empty.totalUsage == 0)
        #expect(empty.userUsage == 0)
        #expect(empty.systemUsage == 0)
        #expect(empty.coreUsages.isEmpty)
        #expect(empty.topProcesses.isEmpty)
    }

    @Test func memoryInfoEmpty() async throws {
        let empty = MemoryInfo.empty
        #expect(empty.total == 0)
        #expect(empty.used == 0)
        #expect(empty.pressure == .nominal)
        #expect(empty.topProcesses.isEmpty)
    }

    @Test func batteryInfoEmpty() async throws {
        let empty = BatteryInfo.empty
        #expect(empty.level == 0)
        #expect(empty.health == 0)
        #expect(empty.cycleCount == 0)
        #expect(empty.isCharging == false)
        #expect(empty.isPluggedIn == false)
        #expect(empty.timeRemaining == nil)
        #expect(empty.temperature == nil)
    }

    @Test func thermalInfoEmpty() async throws {
        let empty = ThermalInfo.empty
        #expect(empty.cpuTemperature == nil)
        #expect(empty.gpuTemperature == nil)
        #expect(empty.fans.isEmpty)
    }

    @Test func storageInfoEmpty() async throws {
        let empty = StorageInfo.empty
        #expect(empty.total == 0)
        #expect(empty.used == 0)
        #expect(empty.free == 0)
        #expect(empty.readBytesPerSec == 0)
        #expect(empty.writeBytesPerSec == 0)
    }

    @Test func processSnapshotIdentifiable() async throws {
        let process = ProcessSnapshot(pid: 123, name: "test", executablePath: "/usr/bin/test", cpuUsage: 5.0, memoryBytes: 1024)
        #expect(process.id == 123)
        #expect(process.name == "test")
    }

    // MARK: - Enum Tests

    @Test func refreshRateValues() async throws {
        #expect(RefreshRate.oneSecond.rawValue == 1.0)
        #expect(RefreshRate.twoSeconds.rawValue == 2.0)
        #expect(RefreshRate.fiveSeconds.rawValue == 5.0)
    }

    @Test func temperatureUnitDisplayNames() async throws {
        #expect(TemperatureUnit.celsius.displayName == "°C")
        #expect(TemperatureUnit.fahrenheit.displayName == "°F")
    }

    @Test func menuBarDisplayModeDisplayNames() async throws {
        #expect(MenuBarDisplayMode.iconOnly.displayName == "Icon only")
        #expect(MenuBarDisplayMode.iconAndCPU.displayName == "Icon + CPU %")
        #expect(MenuBarDisplayMode.iconAndTemp.displayName == "Icon + Temperature")
    }

    @Test func memoryPressureRawValues() async throws {
        #expect(MemoryPressure.nominal.rawValue == "Nominal")
        #expect(MemoryPressure.warning.rawValue == "Warning")
        #expect(MemoryPressure.critical.rawValue == "Critical")
    }
}
