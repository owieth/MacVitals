import Foundation
import UserNotifications

@MainActor
class AlertManager {
    static let shared = AlertManager()

    private var highCPUStart: Date?
    private var lastDiskAlert: Date?
    private var lastBatteryAlert: Date?
    private var lastMemoryAlert: Date?
    private let alertCooldown: TimeInterval = 300
    private var hasRequestedPermission = false

    private init() {}

    func evaluate(snapshot: SystemSnapshot) {
        guard !ProcessInfo.processInfo.environment.keys.contains("XCTestBundlePath") else { return }
        if !hasRequestedPermission {
            hasRequestedPermission = true
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }

        let prefs = UserPreferences.shared
        checkCPU(snapshot.cpu, threshold: prefs.cpuAlertThreshold)
        if prefs.memoryAlertEnabled {
            checkMemory(snapshot.memory)
        }
        checkStorage(snapshot.storage, threshold: prefs.storageAlertThreshold)
        if let battery = snapshot.battery {
            checkBattery(battery, threshold: prefs.batteryAlertThreshold)
        }
    }

    private func checkCPU(_ cpu: CPUInfo, threshold: Double) {
        if cpu.totalUsage > threshold {
            if highCPUStart == nil { highCPUStart = Date() }
            if let start = highCPUStart, Date().timeIntervalSince(start) > 300 {
                sendNotification(
                    title: "High CPU Usage",
                    body: "CPU has been above \(Formatters.percentage(threshold)) for 5 minutes (\(Formatters.percentage(cpu.totalUsage)))"
                )
                highCPUStart = nil
            }
        } else {
            highCPUStart = nil
        }
    }

    private func checkMemory(_ memory: MemoryInfo) {
        guard memory.pressure == .critical, canAlert(&lastMemoryAlert) else { return }
        sendNotification(
            title: "High Memory Pressure",
            body: "Memory usage is critical (\(Formatters.percentage(memory.usagePercentage)))"
        )
    }

    private func checkStorage(_ storage: StorageInfo, threshold: Double) {
        guard storage.usagePercentage > threshold, canAlert(&lastDiskAlert) else { return }
        sendNotification(
            title: "Disk Almost Full",
            body: "Storage is \(Formatters.percentage(storage.usagePercentage)) full"
        )
    }

    private func checkBattery(_ battery: BatteryInfo, threshold: Double) {
        guard battery.level < threshold, !battery.isCharging, canAlert(&lastBatteryAlert) else { return }
        sendNotification(
            title: "Low Battery",
            body: "Battery is at \(Formatters.percentage(battery.level))"
        )
    }

    private func canAlert(_ lastAlert: inout Date?) -> Bool {
        let now = Date()
        if let last = lastAlert, now.timeIntervalSince(last) < alertCooldown { return false }
        lastAlert = now
        return true
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
