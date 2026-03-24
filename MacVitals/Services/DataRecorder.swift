import Foundation

@MainActor
class DataRecorder {
    static let shared = DataRecorder()

    private var buffer: [SystemSnapshot] = []
    private let maxDuration: TimeInterval = 3600

    private init() {}

    func record(_ snapshot: SystemSnapshot) {
        buffer.append(snapshot)
        let cutoff = Date().addingTimeInterval(-maxDuration)
        buffer.removeAll { $0.timestamp < cutoff }
    }

    var snapshotCount: Int { buffer.count }

    func exportCSV(lastMinutes: Int) -> URL? {
        let cutoff = Date().addingTimeInterval(-Double(lastMinutes * 60))
        let filtered = buffer.filter { $0.timestamp >= cutoff }
        guard !filtered.isEmpty else { return nil }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var csv = "timestamp,cpu_percent,memory_percent,disk_read_bytes_sec,disk_write_bytes_sec,net_download_bytes_sec,net_upload_bytes_sec,cpu_temp_c,gpu_temp_c,battery_percent\n"

        for snap in filtered {
            let ts = dateFormatter.string(from: snap.timestamp)
            let cpu = String(format: "%.1f", snap.cpu.totalUsage)
            let mem = String(format: "%.1f", snap.memory.usagePercentage)
            let diskR = "\(snap.storage.readBytesPerSec)"
            let diskW = "\(snap.storage.writeBytesPerSec)"
            let netD = "\(snap.network.downloadBytesPerSec)"
            let netU = "\(snap.network.uploadBytesPerSec)"
            let cpuTemp = snap.thermal.cpuTemperature.map { String(format: "%.1f", $0) } ?? ""
            let gpuTemp = snap.thermal.gpuTemperature.map { String(format: "%.1f", $0) } ?? ""
            let battery = snap.battery.map { String(format: "%.0f", $0.level) } ?? ""

            csv += "\(ts),\(cpu),\(mem),\(diskR),\(diskW),\(netD),\(netU),\(cpuTemp),\(gpuTemp),\(battery)\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "MacVitals_\(Int(Date().timeIntervalSince1970)).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
