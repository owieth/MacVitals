import SwiftUI

struct OverviewSection: View {
    let snapshot: SystemSnapshot?
    var cpuHistory: [Double] = []
    var memoryHistory: [Double] = []

    var body: some View {
        VStack(spacing: 12) {
            if let snapshot {
                Text("Uptime: \(Formatters.uptime(snapshot.uptime))")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 20) {
                    ringGauge(
                        title: "CPU",
                        value: snapshot.cpu.totalUsage,
                        gradient: RingGradients.forUsage(snapshot.cpu.totalUsage)
                    )

                    ringGauge(
                        title: "Memory",
                        value: snapshot.memory.usagePercentage,
                        gradient: RingGradients.forUsage(snapshot.memory.usagePercentage)
                    )

                    if let gpu = snapshot.gpu {
                        ringGauge(
                            title: "GPU",
                            value: gpu.utilizationPercentage,
                            gradient: RingGradients.forUsage(gpu.utilizationPercentage)
                        )
                    }
                }
                .frame(maxWidth: .infinity)

                if !cpuHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CPU")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        PulseLineView(data: cpuHistory)
                            .frame(height: 32)
                    }
                }
            } else {
                Text("Loading...")
                    .font(Theme.Fonts.dataValue)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private func ringGauge(
        title: String,
        value: Double,
        gradient: AngularGradient
    ) -> some View {
        VStack(spacing: 6) {
            RingGaugeView(
                value: value / 100,
                lineWidth: 5,
                gradient: gradient
            ) {
                Text(Formatters.percentage(value))
                    .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .frame(width: 64, height: 64)

            Text(title)
                .font(Theme.Fonts.dataLabel)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

extension Color {
    static func forUsage(_ percentage: Double) -> Color {
        Theme.Colors.forUsage(percentage)
    }
}
