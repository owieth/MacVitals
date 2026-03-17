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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iconOnly: return "Icon only"
        case .iconAndCPU: return "Icon + CPU %"
        case .iconAndTemp: return "Icon + Temperature"
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

    private init() {
        UserDefaults.standard.register(defaults: [
            "showCPUSection": true,
            "showMemorySection": true,
            "showStorageSection": true,
            "showBatterySection": true,
            "showThermalSection": true,
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
