import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            DisplaySettingsView()
                .tabItem { Label("Display", systemImage: "eye") }

            NotificationSettingsView()
                .tabItem { Label("Notifications", systemImage: "bell") }

            DataSettingsView()
                .tabItem { Label("Data", systemImage: "square.and.arrow.up") }

            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 420, height: 380)
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
                Toggle("Network", isOn: $preferences.showNetworkSection)
                Toggle("Thermals", isOn: $preferences.showThermalSection)
            }
        }
        .formStyle(.grouped)
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        Form {
            Section("CPU") {
                HStack {
                    Text("Alert when above")
                    Spacer()
                    Text(Formatters.percentage(preferences.cpuAlertThreshold))
                        .monospacedDigit()
                        .frame(width: 40)
                }
                Slider(value: $preferences.cpuAlertThreshold, in: 50...100, step: 5)
                Text("Triggers after sustained for 5 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Memory") {
                Toggle("Alert on critical pressure", isOn: $preferences.memoryAlertEnabled)
            }

            Section("Storage") {
                HStack {
                    Text("Alert when above")
                    Spacer()
                    Text(Formatters.percentage(preferences.storageAlertThreshold))
                        .monospacedDigit()
                        .frame(width: 40)
                }
                Slider(value: $preferences.storageAlertThreshold, in: 70...99, step: 1)
            }

            Section("Battery") {
                HStack {
                    Text("Alert when below")
                    Spacer()
                    Text(Formatters.percentage(preferences.batteryAlertThreshold))
                        .monospacedDigit()
                        .frame(width: 40)
                }
                Slider(value: $preferences.batteryAlertThreshold, in: 5...50, step: 5)
                Text("Only when not charging")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct DataSettingsView: View {
    @EnvironmentObject var preferences: UserPreferences
    @State private var showExport = false

    var body: some View {
        Form {
            Section("Recording") {
                HStack {
                    Text("Snapshots in buffer")
                    Spacer()
                    Text("\(DataRecorder.shared.snapshotCount)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Text("Up to 1 hour of data is kept in memory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Export") {
                Button("Export to CSV...") {
                    showExport = true
                }
            }

            Section("Web Dashboard") {
                Toggle("Enable web dashboard", isOn: $preferences.webDashboardEnabled)
                    .onChange(of: preferences.webDashboardEnabled) {
                        SystemMonitor.shared.updateWebServer()
                    }

                HStack {
                    Text("Port")
                    Spacer()
                    TextField("Port", value: $preferences.webDashboardPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }

                if preferences.webDashboardEnabled {
                    HStack {
                        Text("URL")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("http://localhost:\(preferences.webDashboardPort)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showExport) {
            ExportView()
        }
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
