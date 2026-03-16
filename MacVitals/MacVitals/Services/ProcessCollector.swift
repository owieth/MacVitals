import Foundation
import Darwin

struct ProcessCollector {
    func collectTopByCPU(limit: Int = 5) -> [ProcessSnapshot] {
        let processes = gatherProcesses()
        return Array(processes.sorted { $0.cpuUsage > $1.cpuUsage }.prefix(limit))
    }

    func collectTopByMemory(limit: Int = 5) -> [ProcessSnapshot] {
        let processes = gatherProcesses()
        return Array(processes.sorted { $0.memoryBytes > $1.memoryBytes }.prefix(limit))
    }

    private func gatherProcesses() -> [ProcessSnapshot] {
        let pids = allPids()
        var processes: [ProcessSnapshot] = []

        for pid in pids {
            guard let info = processInfo(pid: pid) else { continue }
            if info.memoryBytes > 0 {
                processes.append(info)
            }
        }

        return processes
    }

    private func allPids() -> [Int32] {
        let bufferSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bufferSize > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(bufferSize) / MemoryLayout<Int32>.size)
        proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, bufferSize)
        return pids.filter { $0 > 0 }
    }

    private func processInfo(pid: Int32) -> ProcessSnapshot? {
        var taskInfo = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, size)
        guard result == size else { return nil }

        var nameBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        proc_pidpath(pid, &nameBuffer, UInt32(MAXPATHLEN))
        let path = nameBuffer.withUnsafeBufferPointer { buf in
            String(decoding: buf.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
        }
        let name = (path as NSString).lastPathComponent
        guard !name.isEmpty else { return nil }

        let totalTime = Double(taskInfo.pti_total_user + taskInfo.pti_total_system)
        let cpuUsage = totalTime / 1_000_000_000
        let memoryBytes = UInt64(taskInfo.pti_resident_size)

        return ProcessSnapshot(pid: pid, name: name, cpuUsage: cpuUsage, memoryBytes: memoryBytes)
    }
}
