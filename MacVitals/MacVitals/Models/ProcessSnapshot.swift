import Foundation

struct ProcessSnapshot: Identifiable {
    let pid: Int32
    let name: String
    let cpuUsage: Double
    let memoryBytes: UInt64

    var id: Int32 { pid }
}
