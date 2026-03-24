import SwiftUI

struct ThermalSectionView: View {
    let thermal: ThermalInfo
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Thermals")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)

            if thermal.cpuTemperature != nil || thermal.gpuTemperature != nil {
                HStack(spacing: 16) {
                    if let cpuTemp = thermal.cpuTemperature {
                        StatLabel(
                            title: "CPU",
                            value: Formatters.temperature(cpuTemp, unit: preferences.temperatureUnit)
                        )
                    }
                    if let gpuTemp = thermal.gpuTemperature {
                        StatLabel(
                            title: "GPU",
                            value: Formatters.temperature(gpuTemp, unit: preferences.temperatureUnit)
                        )
                    }
                }
            }

            if !thermal.fans.isEmpty {
                ForEach(thermal.fans) { fan in
                    HStack {
                        Text("Fan \(fan.id + 1)")
                            .font(Theme.Fonts.dataLabel)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Spacer()
                        Text(Formatters.rpm(fan.currentRPM))
                            .font(Theme.Fonts.dataValue)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
            } else if thermal.cpuTemperature != nil || thermal.gpuTemperature != nil {
                Text("No fans detected")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            if !thermal.allSensors.isEmpty {
                DisclosureGroup {
                    sensorList
                } label: {
                    Text("All Sensors (\(thermal.allSensors.count))")
                        .font(Theme.Fonts.dataLabel)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .tint(Theme.Colors.textTertiary)
            }

            if thermal.isEmpty {
                Text("No thermal data available")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
    }

    private var sensorList: some View {
        let grouped = Dictionary(grouping: thermal.allSensors, by: \.category)
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(SensorCategory.allCases, id: \.self) { category in
                if let sensors = grouped[category], !sensors.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.rawValue)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.accentCyan)

                        ForEach(sensors) { sensor in
                            HStack {
                                Text(sensor.label)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                Spacer()
                                Text(Formatters.temperature(sensor.value, unit: preferences.temperatureUnit))
                                    .font(Theme.Fonts.caption.monospacedDigit())
                                    .foregroundStyle(Theme.Colors.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }
}
