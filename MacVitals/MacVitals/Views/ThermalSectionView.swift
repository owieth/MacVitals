import SwiftUI

struct ThermalSectionView: View {
    let thermal: ThermalInfo
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        DisclosureGroup("Thermals") {
            VStack(alignment: .leading, spacing: 8) {
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
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(Formatters.rpm(fan.currentRPM))
                                .font(.caption.monospacedDigit())
                        }
                    }
                } else if thermal.cpuTemperature != nil || thermal.gpuTemperature != nil {
                    Text("No fans detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if thermal.cpuTemperature == nil && thermal.gpuTemperature == nil && thermal.fans.isEmpty {
                    Text("No thermal data available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }
}
