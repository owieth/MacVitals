import Foundation

@MainActor
class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()

    @Published var snapshot: SystemSnapshot?

    private var timer: Timer?

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
        let uptime = ProcessInfo.processInfo.systemUptime

        snapshot = SystemSnapshot(
            timestamp: Date(),
            cpu: .empty,
            memory: .empty,
            storage: .empty,
            battery: nil,
            thermal: .empty,
            uptime: uptime
        )
    }
}
