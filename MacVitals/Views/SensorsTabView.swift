import SwiftUI

struct SensorsTabView: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sectionSpacing) {
                if let thermal = monitor.snapshot?.thermal, !thermal.allSensors.isEmpty {
                    let grouped = Dictionary(grouping: thermal.allSensors, by: \.category)
                    ForEach(SensorCategory.allCases, id: \.self) { category in
                        if let sensors = grouped[category], !sensors.isEmpty {
                            sensorGroup(title: category.rawValue, sensors: sensors)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Text("No sensor data available")
                            .font(Theme.Fonts.dataValue)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }

                if let thermal = monitor.snapshot?.thermal, !thermal.fans.isEmpty {
                    fansSection(fans: thermal.fans)
                }
            }
            .padding(Theme.Spacing.contentPadding)
        }
    }

    private func sensorGroup(title: String, sensors: [SensorReading]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.accentCyan)
                .padding(.bottom, 2)

            ForEach(sensors) { sensor in
                HStack {
                    Text(sensor.label)
                        .font(Theme.Fonts.dataLabel)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text(Formatters.temperature(sensor.value, unit: preferences.temperatureUnit))
                        .font(Theme.Fonts.dataValue)
                        .foregroundStyle(temperatureColor(sensor.value))
                }
                .padding(.vertical, 2)
            }
        }
        .cardStyle()
    }

    private func fansSection(fans: [FanInfo]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fans")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.accentCyan)
                .padding(.bottom, 2)

            ForEach(fans) { fan in
                HStack {
                    Text("Fan \(fan.id + 1)")
                        .font(Theme.Fonts.dataLabel)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text(Formatters.rpm(fan.currentRPM))
                        .font(Theme.Fonts.dataValue)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if fan.maxRPM > 0 {
                        Text("/ \(fan.maxRPM)")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .cardStyle()
    }

    private func temperatureColor(_ celsius: Double) -> Color {
        if celsius > 90 { return Theme.Colors.criticalRed }
        if celsius > 70 { return Theme.Colors.warningOrange }
        return Theme.Colors.textPrimary
    }
}
