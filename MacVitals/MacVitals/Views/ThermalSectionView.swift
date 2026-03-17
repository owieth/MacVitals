import SwiftUI

struct ThermalSectionView: View {
    let thermal: ThermalInfo
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        DisclosureGroup("Thermals") {
            VStack(alignment: .leading, spacing: 8) {
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

                if thermal.isEmpty {
                    Text("No thermal data available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }
}
