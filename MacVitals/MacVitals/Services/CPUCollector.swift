import Foundation
import Darwin

struct CPUCollector {
    private var previousTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []

    mutating func collect() -> CPUInfo {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo else {
            return .empty
        }

        defer {
            vm_deallocate(
                mv_mach_task_self(),
                vm_address_t(bitPattern: cpuInfo),
                vm_size_t(Int(numCPUInfo) * MemoryLayout<integer_t>.size)
            )
        }

        var currentTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
        var coreUsages: [Double] = []
        var totalUser: Double = 0
        var totalSystem: Double = 0
        var totalIdle: Double = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = UInt64(cpuInfo[offset + Int(CPU_STATE_USER)])
            let system = UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idle = UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let nice = UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])

            currentTicks.append((user: user, system: system, idle: idle, nice: nice))

            if i < previousTicks.count {
                let dUser = Double(user - previousTicks[i].user)
                let dSystem = Double(system - previousTicks[i].system)
                let dIdle = Double(idle - previousTicks[i].idle)
                let dNice = Double(nice - previousTicks[i].nice)
                let total = dUser + dSystem + dIdle + dNice

                if total > 0 {
                    let coreUsage = ((dUser + dSystem + dNice) / total) * 100
                    coreUsages.append(coreUsage)
                    totalUser += dUser
                    totalSystem += dSystem
                    totalIdle += dIdle
                } else {
                    coreUsages.append(0)
                }
            } else {
                coreUsages.append(0)
            }
        }

        previousTicks = currentTicks

        let grandTotal = totalUser + totalSystem + totalIdle
        let totalUsage = grandTotal > 0 ? ((totalUser + totalSystem) / grandTotal) * 100 : 0
        let userUsage = grandTotal > 0 ? (totalUser / grandTotal) * 100 : 0
        let systemUsage = grandTotal > 0 ? (totalSystem / grandTotal) * 100 : 0

        return CPUInfo(
            totalUsage: totalUsage,
            userUsage: userUsage,
            systemUsage: systemUsage,
            coreUsages: coreUsages,
            topProcesses: []
        )
    }
}
