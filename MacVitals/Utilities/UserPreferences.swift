import Foundation
import ServiceManagement

enum RefreshRate: Double, CaseIterable, Identifiable {
    case oneSecond = 1.0
    case twoSeconds = 2.0
    case fiveSeconds = 5.0

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .oneSecond: return "1 second"
        case .twoSeconds: return "2 seconds"
        case .fiveSeconds: return "5 seconds"
        }
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case iconOnly = "iconOnly"
    case iconAndCPU = "iconAndCPU"
    case iconAndTemp = "iconAndTemp"
    case cpuGraph = "cpuGraph"
    case memoryRing = "memoryRing"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iconOnly: return "Icon only"
        case .iconAndCPU: return "Icon + CPU %"
        case .iconAndTemp: return "Icon + Temperature"
        case .cpuGraph: return "CPU bar graph"
        case .memoryRing: return "Memory ring"
        }
    }
}

@MainActor
class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    @Published var refreshRate: RefreshRate {
        didSet {
            UserDefaults.standard.set(refreshRate.rawValue, forKey: "refreshRate")
        }
    }

    @Published var menuBarDisplayMode: MenuBarDisplayMode {
        didSet {
            UserDefaults.standard.set(menuBarDisplayMode.rawValue, forKey: "menuBarDisplayMode")
        }
    }

    @Published var temperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
        }
    }

    @Published var showCPUSection: Bool {
        didSet { UserDefaults.standard.set(showCPUSection, forKey: "showCPUSection") }
    }

    @Published var showMemorySection: Bool {
        didSet { UserDefaults.standard.set(showMemorySection, forKey: "showMemorySection") }
    }

    @Published var showStorageSection: Bool {
        didSet { UserDefaults.standard.set(showStorageSection, forKey: "showStorageSection") }
    }

    @Published var showBatterySection: Bool {
        didSet { UserDefaults.standard.set(showBatterySection, forKey: "showBatterySection") }
    }

    @Published var showThermalSection: Bool {
        didSet { UserDefaults.standard.set(showThermalSection, forKey: "showThermalSection") }
    }

    @Published var showNetworkSection: Bool {
        didSet { UserDefaults.standard.set(showNetworkSection, forKey: "showNetworkSection") }
    }

    @Published var showExternalIP: Bool {
        didSet { UserDefaults.standard.set(showExternalIP, forKey: "showExternalIP") }
    }

    @Published var selectedTab: Int {
        didSet { UserDefaults.standard.set(selectedTab, forKey: "selectedTab") }
    }

    @Published var sectionOrder: [String] {
        didSet { UserDefaults.standard.set(sectionOrder, forKey: "sectionOrder") }
    }

    @Published var cpuAlertThreshold: Double {
        didSet { UserDefaults.standard.set(cpuAlertThreshold, forKey: "cpuAlertThreshold") }
    }

    @Published var memoryAlertEnabled: Bool {
        didSet { UserDefaults.standard.set(memoryAlertEnabled, forKey: "memoryAlertEnabled") }
    }

    @Published var storageAlertThreshold: Double {
        didSet { UserDefaults.standard.set(storageAlertThreshold, forKey: "storageAlertThreshold") }
    }

    @Published var batteryAlertThreshold: Double {
        didSet { UserDefaults.standard.set(batteryAlertThreshold, forKey: "batteryAlertThreshold") }
    }

    @Published var webDashboardEnabled: Bool {
        didSet { UserDefaults.standard.set(webDashboardEnabled, forKey: "webDashboardEnabled") }
    }

    @Published var webDashboardPort: Int {
        didSet { UserDefaults.standard.set(webDashboardPort, forKey: "webDashboardPort") }
    }

    static let defaultSectionOrder = ["cpu", "memory", "storage", "battery", "network", "gpu", "thermal", "bluetooth"]

    private init() {
        UserDefaults.standard.register(defaults: [
            "showCPUSection": true,
            "showMemorySection": true,
            "showStorageSection": true,
            "showBatterySection": true,
            "showThermalSection": true,
            "showNetworkSection": true,
        ])

        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")

        let savedRate = UserDefaults.standard.double(forKey: "refreshRate")
        self.refreshRate = RefreshRate(rawValue: savedRate) ?? .twoSeconds

        let savedMode = UserDefaults.standard.string(forKey: "menuBarDisplayMode") ?? MenuBarDisplayMode.iconOnly.rawValue
        self.menuBarDisplayMode = MenuBarDisplayMode(rawValue: savedMode) ?? .iconOnly

        let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? TemperatureUnit.celsius.rawValue
        self.temperatureUnit = TemperatureUnit(rawValue: savedUnit) ?? .celsius

        self.showCPUSection = UserDefaults.standard.bool(forKey: "showCPUSection")
        self.showMemorySection = UserDefaults.standard.bool(forKey: "showMemorySection")
        self.showStorageSection = UserDefaults.standard.bool(forKey: "showStorageSection")
        self.showBatterySection = UserDefaults.standard.bool(forKey: "showBatterySection")
        self.showThermalSection = UserDefaults.standard.bool(forKey: "showThermalSection")
        self.showNetworkSection = UserDefaults.standard.bool(forKey: "showNetworkSection")
        self.showExternalIP = UserDefaults.standard.bool(forKey: "showExternalIP")
        self.selectedTab = UserDefaults.standard.integer(forKey: "selectedTab")
        self.sectionOrder = (UserDefaults.standard.stringArray(forKey: "sectionOrder")) ?? Self.defaultSectionOrder
        self.cpuAlertThreshold = UserDefaults.standard.object(forKey: "cpuAlertThreshold") as? Double ?? 90
        self.memoryAlertEnabled = UserDefaults.standard.object(forKey: "memoryAlertEnabled") as? Bool ?? true
        self.storageAlertThreshold = UserDefaults.standard.object(forKey: "storageAlertThreshold") as? Double ?? 95
        self.batteryAlertThreshold = UserDefaults.standard.object(forKey: "batteryAlertThreshold") as? Double ?? 20
        self.webDashboardEnabled = UserDefaults.standard.bool(forKey: "webDashboardEnabled")
        self.webDashboardPort = UserDefaults.standard.object(forKey: "webDashboardPort") as? Int ?? 8765
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
