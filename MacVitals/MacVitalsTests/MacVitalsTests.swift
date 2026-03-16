import Testing
@testable import MacVitals

struct MacVitalsTests {
    @Test func formatPercentage() async throws {
        #expect(Formatters.percentage(62.4) == "62%")
        #expect(Formatters.percentage(0) == "0%")
        #expect(Formatters.percentage(100) == "100%")
    }

    @Test func formatUptime() async throws {
        #expect(Formatters.uptime(3600) == "1h 0m")
        #expect(Formatters.uptime(90000) == "1d 1h 0m")
        #expect(Formatters.uptime(300) == "5m")
    }

    @Test func formatTemperatureCelsius() async throws {
        #expect(Formatters.temperature(62.0, unit: .celsius) == "62°C")
    }

    @Test func formatTemperatureFahrenheit() async throws {
        #expect(Formatters.temperature(0.0, unit: .fahrenheit) == "32°F")
        #expect(Formatters.temperature(100.0, unit: .fahrenheit) == "212°F")
    }

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
}
