import SwiftUI

struct BatterySectionView: View {
    let battery: BatteryInfo

    var body: some View {
        DisclosureGroup("Battery") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Formatters.percentage(battery.level))
                        .font(.caption.monospacedDigit())
                    if battery.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("Charging")
                            .font(.caption)
                    } else if battery.isPluggedIn {
                        Text("Plugged In")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Health: \(Formatters.percentage(battery.health))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    StatLabel(title: "Cycles", value: "\(battery.cycleCount)")
                    if let remaining = battery.timeRemaining {
                        StatLabel(title: "ETA", value: Formatters.uptime(remaining))
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}
