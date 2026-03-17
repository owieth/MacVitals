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
    private var processCollector = ProcessCollector()
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

        let cpuWithProcesses = CPUInfo(
            totalUsage: cpu.totalUsage,
            userUsage: cpu.userUsage,
            systemUsage: cpu.systemUsage,
            coreUsages: cpu.coreUsages,
            topProcesses: topByCPU
        )

        let memoryWithProcesses = MemoryInfo(
            total: memory.total,
            used: memory.used,
            active: memory.active,
            wired: memory.wired,
            compressed: memory.compressed,
            available: memory.available,
            pressure: memory.pressure,
            topProcesses: topByMemory
        )

        snapshot = SystemSnapshot(
            timestamp: Date(),
            cpu: cpuWithProcesses,
            memory: memoryWithProcesses,
            storage: storage,
            battery: battery,
            thermal: thermal,
            uptime: uptime
        )
    }
}
