import os.log
import Foundation

@MainActor
class SystemMonitor: ObservableObject {
    static let shared = SystemMonitor()
    private let logger = Logger(subsystem: "com.macvitals.app", category: "SystemMonitor")

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
    private var thermalCollector = ThermalCollector()
    private var networkCollector = NetworkCollector()
    private let gpuCollector = GPUCollector()
    private var processCollector = ProcessCollector()
    private let smcClient = SMCClient()

    private init() {}

    func start() {
        logger.info("Starting system monitor")
        stop()
        if !smcClient.open() {
            logger.warning("Failed to open SMC connection — thermal data will be unavailable")
        } else {
            thermalCollector.discoverKeys(using: smcClient)
        }

        let interval = UserPreferences.shared.refreshRate.rawValue
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.collectSnapshot()
            }
        }
        collectSnapshot()
    }

    func stop() {
        logger.info("Stopping system monitor")
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
        let network = networkCollector.collect()
        let gpu = gpuCollector.collect()
        let uptime = ProcessInfo.processInfo.systemUptime

        tickCount += 1
        let shouldCollectProcesses = isPopoverVisible || tickCount % 3 == 0
        let topByCPU: [ProcessSnapshot]
        let topByMemory: [ProcessSnapshot]
        if shouldCollectProcesses {
            let topProcesses = processCollector.collectTop()
            topByCPU = topProcesses.cpu
            topByMemory = topProcesses.memory
        } else {
            topByCPU = snapshot?.cpu.topProcesses ?? []
            topByMemory = snapshot?.memory.topProcesses ?? []
        }

        cpuHistory.append(cpu.totalUsage)
        if cpuHistory.count > maxHistorySize { cpuHistory.removeFirst() }
        memoryHistory.append(memory.usagePercentage)
        if memoryHistory.count > maxHistorySize { memoryHistory.removeFirst() }

        let newSnapshot = SystemSnapshot(
            timestamp: Date(),
            cpu: cpu.with(topProcesses: topByCPU),
            memory: memory.with(topProcesses: topByMemory),
            storage: storage,
            battery: battery,
            thermal: thermal,
            network: network,
            gpu: gpu,
            uptime: uptime
        )
        snapshot = newSnapshot
        if timer != nil {
            AlertManager.shared.evaluate(snapshot: newSnapshot)
        }
    }
}
