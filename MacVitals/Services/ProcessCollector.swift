import Foundation
import Darwin
import os.log

struct ProcessCollector {
    private static let logger = Logger(subsystem: "com.macvitals.app", category: "ProcessCollector")
    private var previousSamples: [Int32: (totalTime: UInt64, timestamp: TimeInterval)] = [:]

    mutating func collectTop(cpuLimit: Int = 5, memoryLimit: Int = 5) -> (cpu: [ProcessSnapshot], memory: [ProcessSnapshot]) {
        let processes = gatherProcesses()
        let topCPU = Array(processes.sorted { $0.cpuUsage > $1.cpuUsage }.prefix(cpuLimit))
        let topMemory = Array(processes.sorted { $0.memoryBytes > $1.memoryBytes }.prefix(memoryLimit))
        return (topCPU, topMemory)
    }

    mutating func collectAll() -> [ProcessSnapshot] {
        gatherProcesses()
    }

    private mutating func gatherProcesses() -> [ProcessSnapshot] {
        let pids = allPids()
        var processes: [ProcessSnapshot] = []
        let now = ProcessInfo.processInfo.systemUptime
        let coreCount = Double(ProcessInfo.processInfo.activeProcessorCount)
        var newSamples: [Int32: (totalTime: UInt64, timestamp: TimeInterval)] = [:]

        for pid in pids {
            guard let info = processInfo(pid: pid, now: now, coreCount: coreCount, newSamples: &newSamples) else { continue }
            if info.memoryBytes > 0 {
                processes.append(info)
            }
        }

        previousSamples = newSamples
        return processes
    }

    private func allPids() -> [Int32] {
        let bufferSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bufferSize > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(bufferSize) / MemoryLayout<Int32>.size)
        proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, bufferSize)
        return pids.filter { $0 > 0 }
    }

    private func processInfo(
        pid: Int32,
        now: TimeInterval,
        coreCount: Double,
        newSamples: inout [Int32: (totalTime: UInt64, timestamp: TimeInterval)]
    ) -> ProcessSnapshot? {
        var taskInfo = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, size)
        guard result == size else { return nil }

        var nameBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        proc_pidpath(pid, &nameBuffer, UInt32(MAXPATHLEN))
        let path = String(cString: nameBuffer)
        let name = URL(fileURLWithPath: path).lastPathComponent
        guard !name.isEmpty else { return nil }

        let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
        newSamples[pid] = (totalTime: totalTime, timestamp: now)

        var cpuUsage = 0.0
        if let previous = previousSamples[pid] {
            let deltaTime = now - previous.timestamp
            if deltaTime > 0 && totalTime >= previous.totalTime {
                let deltaCPU = Double(totalTime - previous.totalTime) / 1_000_000_000
                cpuUsage = (deltaCPU / deltaTime / coreCount) * 100
            }
        }

        let memoryBytes = UInt64(taskInfo.pti_resident_size)
        return ProcessSnapshot(pid: pid, name: name, cpuUsage: cpuUsage, memoryBytes: memoryBytes)
    }
}
