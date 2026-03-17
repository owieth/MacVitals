import Foundation

@MainActor
class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()

    @Published var snapshot: SystemSnapshot?

    private var timer: Timer?
    private var cpuCollector = CPUCollector()
    private let memoryCollector = MemoryCollector()
    private var storageCollector = StorageCollector()
    private let batteryCollector = BatteryCollector()
    private let thermalCollector = ThermalCollector()
    private let processCollector = ProcessCollector()
    private let smcClient = SMCClient()

    private init() {}

    func start() {
        _ = smcClient.open()

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
        smcClient.close()
    }

    func restart() {
        stop()
        start()
    }

    private func collectSnapshot() {
        let cpu = cpuCollector.collect()
        let memory = memoryCollector.collect()
        let storage = storageCollector.collect()
        let battery = batteryCollector.collect()
        let thermal = thermalCollector.collect(using: smcClient)
        let uptime = ProcessInfo.processInfo.systemUptime

        let topByCPU = processCollector.collectTopByCPU()
        let topByMemory = processCollector.collectTopByMemory()

        snapshot = SystemSnapshot(
            timestamp: Date(),
            cpu: cpu.with(topProcesses: topByCPU),
            memory: memory.with(topProcesses: topByMemory),
            storage: storage,
            battery: battery,
            thermal: thermal,
            uptime: uptime
        )
    }
}
