import Foundation

@MainActor
class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()

    @Published var snapshot: SystemSnapshot?
    var isPopoverVisible = false
    @Published var cpuHistory: [Double] = []
    @Published var memoryHistory: [Double] = []
    private let maxHistorySize = 60

    private var timer: Timer?
    private var tickCount = 0
    private var cpuCollector = CPUCollector()
    private let memoryCollector = MemoryCollector()
    private var storageCollector = StorageCollector()
    private let batteryCollector = BatteryCollector()
    private let thermalCollector = ThermalCollector()
    private var processCollector = ProcessCollector()
    private let smcClient = SMCClient()

    private init() {}

    func start() {
        stop()
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

        tickCount += 1
        let shouldCollectProcesses = isPopoverVisible || tickCount % 3 == 0
        let topByCPU: [ProcessSnapshot]
        let topByMemory: [ProcessSnapshot]
        if shouldCollectProcesses {
            topByCPU = processCollector.collectTopByCPU()
            topByMemory = processCollector.collectTopByMemory()
        } else {
            topByCPU = snapshot?.cpu.topProcesses ?? []
            topByMemory = snapshot?.memory.topProcesses ?? []
        }

        cpuHistory.append(cpu.totalUsage)
        if cpuHistory.count > maxHistorySize { cpuHistory.removeFirst() }
        memoryHistory.append(memory.usagePercentage)
        if memoryHistory.count > maxHistorySize { memoryHistory.removeFirst() }

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
