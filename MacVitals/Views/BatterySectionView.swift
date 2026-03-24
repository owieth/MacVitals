import SwiftUI

struct BatterySectionView: View {
    let battery: BatteryInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Battery")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: 12) {
                RingGaugeView(
                    value: battery.level / 100,
                    lineWidth: 5,
                    gradient: RingGradients.batteryGradient(level: battery.level)
                ) {
                    VStack(spacing: 0) {
                        Text(Formatters.percentage(battery.level))
                            .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.Colors.textPrimary)
                        if battery.isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if battery.isCharging {
                            Text("Charging")
                                .font(Theme.Fonts.dataValue)
                                .foregroundStyle(.yellow)
                        } else if battery.isPluggedIn {
                            Text("Plugged In")
                                .font(Theme.Fonts.dataValue)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }

                    HStack(spacing: 16) {
                        StatLabel(title: "Health", value: Formatters.percentage(battery.health))
                        StatLabel(title: "Cycles", value: "\(battery.cycleCount)")
                        if let remaining = battery.timeRemaining {
                            StatLabel(title: "ETA", value: Formatters.uptime(remaining))
                        }
                    }
                }
            }
        }
    }
}
