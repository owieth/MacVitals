import Foundation

enum SensorLabelMap {
    struct Entry {
        let label: String
        let category: SensorCategory
    }

    static let map: [String: Entry] = [
        // CPU — Apple Silicon & Intel
        "Tc0p": Entry(label: "CPU Proximity", category: .cpu),
        "Tc0c": Entry(label: "CPU Core 1", category: .cpu),
        "Tc1c": Entry(label: "CPU Core 2", category: .cpu),
        "Tc2c": Entry(label: "CPU Core 3", category: .cpu),
        "Tc3c": Entry(label: "CPU Core 4", category: .cpu),
        "Tc4c": Entry(label: "CPU Core 5", category: .cpu),
        "Tc5c": Entry(label: "CPU Core 6", category: .cpu),
        "Tc6c": Entry(label: "CPU Core 7", category: .cpu),
        "Tc7c": Entry(label: "CPU Core 8", category: .cpu),
        "Tc0a": Entry(label: "CPU Package", category: .cpu),
        "TC0P": Entry(label: "CPU Proximity", category: .cpu),
        "TC0D": Entry(label: "CPU Die", category: .cpu),
        "TC0E": Entry(label: "CPU Efficiency Core 1", category: .cpu),
        "TC0F": Entry(label: "CPU Efficiency Core 2", category: .cpu),
        "TC1E": Entry(label: "CPU Performance Core 1", category: .cpu),
        "TC1F": Entry(label: "CPU Performance Core 2", category: .cpu),
        "TC2E": Entry(label: "CPU Performance Core 3", category: .cpu),
        "TC2F": Entry(label: "CPU Performance Core 4", category: .cpu),
        "Tp01": Entry(label: "CPU P-Core 1", category: .cpu),
        "Tp02": Entry(label: "CPU P-Core 2", category: .cpu),
        "Tp05": Entry(label: "CPU P-Core 3", category: .cpu),
        "Tp06": Entry(label: "CPU P-Core 4", category: .cpu),
        "Tp09": Entry(label: "CPU P-Core 5", category: .cpu),
        "Tp0A": Entry(label: "CPU P-Core 6", category: .cpu),
        "Tp0D": Entry(label: "CPU P-Core 7", category: .cpu),
        "Tp0E": Entry(label: "CPU P-Core 8", category: .cpu),
        "Tp0b": Entry(label: "CPU E-Core 1", category: .cpu),
        "Tp0f": Entry(label: "CPU E-Core 2", category: .cpu),
        "Tp0j": Entry(label: "CPU E-Core 3", category: .cpu),
        "Tp0n": Entry(label: "CPU E-Core 4", category: .cpu),

        // GPU
        "Tg0p": Entry(label: "GPU Proximity", category: .gpu),
        "TG0P": Entry(label: "GPU Proximity", category: .gpu),
        "TG0D": Entry(label: "GPU Die", category: .gpu),
        "Tg0D": Entry(label: "GPU Die", category: .gpu),
        "TG0T": Entry(label: "GPU Transistor", category: .gpu),
        "Tg1p": Entry(label: "GPU 2 Proximity", category: .gpu),

        // Memory
        "Tm0P": Entry(label: "Memory Proximity", category: .memory),
        "Tm0p": Entry(label: "Memory Proximity", category: .memory),
        "Tm1P": Entry(label: "Memory Bank A", category: .memory),
        "Tm1p": Entry(label: "Memory Bank A", category: .memory),
        "Tm2P": Entry(label: "Memory Bank B", category: .memory),
        "Tm2p": Entry(label: "Memory Bank B", category: .memory),

        // Storage / SSD
        "Th0N": Entry(label: "SSD NAND", category: .storage),
        "Th0A": Entry(label: "SSD Controller A", category: .storage),
        "Th0B": Entry(label: "SSD Controller B", category: .storage),
        "TH0P": Entry(label: "HDD Proximity", category: .storage),
        "TH0a": Entry(label: "HDD Bay 1", category: .storage),
        "TH0b": Entry(label: "HDD Bay 2", category: .storage),

        // Ambient / Misc
        "TA0P": Entry(label: "Ambient", category: .ambient),
        "TA0p": Entry(label: "Ambient", category: .ambient),
        "TA1P": Entry(label: "Ambient 2", category: .ambient),
        "TB0T": Entry(label: "Battery TS_MAX", category: .ambient),
        "TB1T": Entry(label: "Battery 1", category: .ambient),
        "TB2T": Entry(label: "Battery 2", category: .ambient),
        "TW0P": Entry(label: "Wireless Proximity", category: .ambient),
        "Ts0P": Entry(label: "Palm Rest 1", category: .ambient),
        "Ts1P": Entry(label: "Palm Rest 2", category: .ambient),
        "TN0P": Entry(label: "Thunderbolt Proximity", category: .ambient),
        "TN1P": Entry(label: "Thunderbolt 2 Proximity", category: .ambient),
        "Tp0C": Entry(label: "Power Supply", category: .ambient),
        "TPCD": Entry(label: "Platform Controller Hub Die", category: .ambient),
        "TL0P": Entry(label: "LCD Proximity", category: .ambient),
        "TI0P": Entry(label: "Thunderbolt 3", category: .ambient),
    ]

    static func label(for key: String) -> String {
        map[key]?.label ?? key
    }

    static func category(for key: String) -> SensorCategory {
        if let entry = map[key] { return entry.category }
        if key.hasPrefix("Tc") || key.hasPrefix("TC") || key.hasPrefix("Tp") { return .cpu }
        if key.hasPrefix("Tg") || key.hasPrefix("TG") { return .gpu }
        if key.hasPrefix("Tm") || key.hasPrefix("TM") { return .memory }
        if key.hasPrefix("Th") || key.hasPrefix("TH") { return .storage }
        if key.hasPrefix("TA") || key.hasPrefix("TB") { return .ambient }
        return .other
    }
}
