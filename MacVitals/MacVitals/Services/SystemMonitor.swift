import Foundation

@MainActor
class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()

    @Published var snapshot: SystemSnapshot?

    private var timer: Timer?
    private var cpuCollector = CPUCollector()
    private let memoryCollector = MemoryCollector()

    private init() {}

    func start() {
        let interval = UserPreferences.shared.refreshRate.rawValue
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.collectSnapshot()
            }
        }
        collectSnapshot()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restart() {
        stop()
        start()
    }

    private func collectSnapshot() {
        let cpu = cpuCollector.collect()
        let memory = memoryCollector.collect()
        let uptime = ProcessInfo.processInfo.systemUptime

        snapshot = SystemSnapshot(
            timestamp: Date(),
            cpu: cpu,
            memory: memory,
            storage: .empty,
            battery: nil,
            thermal: .empty,
            uptime: uptime
        )
    }
}
