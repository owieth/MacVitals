import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            DisplaySettingsView()
                .tabItem { Label("Display", systemImage: "eye") }

            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 420, height: 320)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $preferences.launchAtLogin)

            Picker("Refresh rate", selection: $preferences.refreshRate) {
                ForEach(RefreshRate.allCases) { rate in
                    Text(rate.displayName).tag(rate)
                }
            }
            .onChange(of: preferences.refreshRate) {
                SystemMonitor.shared.restart()
            }

            Picker("Menu bar display", selection: $preferences.menuBarDisplayMode) {
                ForEach(MenuBarDisplayMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct DisplaySettingsView: View {
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        Form {
            Picker("Temperature unit", selection: $preferences.temperatureUnit) {
                ForEach(TemperatureUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }

            Section("Visible Sections") {
                Toggle("CPU", isOn: $preferences.showCPUSection)
                Toggle("Memory", isOn: $preferences.showMemorySection)
                Toggle("Storage", isOn: $preferences.showStorageSection)
                Toggle("Battery", isOn: $preferences.showBatterySection)
                Toggle("Thermals", isOn: $preferences.showThermalSection)
            }
        }
        .formStyle(.grouped)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(Constants.appName)
                .font(.title2.bold())

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(build))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("View on GitHub") {
                Constants.openGitHub()
            }

            Button("Check for Updates") {
                if let url = URL(string: Constants.githubURL + "/releases/latest") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .font(.caption)

            Text("Tip: Press ⌥⇧V to toggle the popover")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
