import Foundation

enum SensorCategory: String, CaseIterable {
    case cpu = "CPU"
    case gpu = "GPU"
    case memory = "Memory"
    case storage = "Storage"
    case ambient = "Ambient"
    case other = "Other"
}

struct SensorReading: Identifiable {
    let id: String
    let label: String
    let value: Double
    let category: SensorCategory
}
