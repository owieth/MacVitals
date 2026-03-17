import Foundation

enum Formatters {
    nonisolated(unsafe) private static let memoryFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .memory
        return f
    }()

    nonisolated(unsafe) private static let fileFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    nonisolated(unsafe) private static let bytesPerSecFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .memory
        f.includesUnit = true
        return f
    }()

    static func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }

    static func bytes(_ value: UInt64) -> String {
        memoryFormatter.string(fromByteCount: Int64(value))
    }

    static func bytesDecimal(_ value: UInt64) -> String {
        fileFormatter.string(fromByteCount: Int64(value))
    }

    static func bytesPerSecond(_ value: UInt64) -> String {
        bytesPerSecFormatter.string(fromByteCount: Int64(value)) + "/s"
    }

    static func temperature(_ celsius: Double, unit: TemperatureUnit) -> String {
        switch unit {
        case .celsius:
            return String(format: "%.0f°C", celsius)
        case .fahrenheit:
            let f = celsius * 9.0 / 5.0 + 32.0
            return String(format: "%.0f°F", f)
        }
    }

    static func uptime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    static func rpm(_ value: Int) -> String {
        "\(value) RPM"
    }
}
