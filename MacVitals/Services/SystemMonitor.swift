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
    @Published var networkDownloadHistory: [Double] = []
    @Published var networkUploadHistory: [Double] = []
    private let maxHistorySize = 120

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
    private let bluetoothCollector = BluetoothCollector()
    private let smcClient = SMCClient()
    private let webServer = WebServer()

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
        updateWebServer()
    }

    func updateWebServer() {
        let prefs = UserPreferences.shared
        if prefs.webDashboardEnabled {
            if !webServer.isRunning {
                webServer.start(port: UInt16(prefs.webDashboardPort))
            }
        } else {
            webServer.stop()
        }
    }

    func stop() {
        logger.info("Stopping system monitor")
        timer?.invalidate()
        timer = nil
        smcClient.close()
        webServer.stop()
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
        if UserPreferences.shared.showExternalIP {
            networkCollector.fetchExternalIPIfNeeded()
        }
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
        networkDownloadHistory.append(Double(network.downloadBytesPerSec))
        if networkDownloadHistory.count > maxHistorySize { networkDownloadHistory.removeFirst() }
        networkUploadHistory.append(Double(network.uploadBytesPerSec))
        if networkUploadHistory.count > maxHistorySize { networkUploadHistory.removeFirst() }

        let bluetooth = tickCount % 3 == 0 ? bluetoothCollector.collect() : (snapshot?.bluetooth ?? [])

        let newSnapshot = SystemSnapshot(
            timestamp: Date(),
            cpu: cpu.with(topProcesses: topByCPU),
            memory: memory.with(topProcesses: topByMemory),
            storage: storage,
            battery: battery,
            thermal: thermal,
            network: network,
            gpu: gpu,
            bluetooth: bluetooth,
            uptime: uptime
        )
        snapshot = newSnapshot
        DataRecorder.shared.record(newSnapshot)
        if timer != nil {
            AlertManager.shared.evaluate(snapshot: newSnapshot)
        }
    }
}
