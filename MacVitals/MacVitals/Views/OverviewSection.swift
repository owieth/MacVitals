import SwiftUI

struct OverviewSection: View {
    let snapshot: SystemSnapshot?

    var body: some View {
        VStack(spacing: 8) {
            if let snapshot {
                Text("Uptime: \(Formatters.uptime(snapshot.uptime))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    MetricBar(
                        label: "CPU",
                        value: snapshot.cpu.totalUsage / 100,
                        displayValue: Formatters.percentage(snapshot.cpu.totalUsage)
                    )
                    MetricBar(
                        label: "Memory",
                        value: snapshot.memory.usagePercentage / 100,
                        displayValue: Formatters.percentage(snapshot.memory.usagePercentage)
                    )
                }
            } else {
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MetricBar: View {
    let label: String
    let value: Double
    let displayValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(displayValue)
                    .font(.caption.monospacedDigit())
            }
            ProgressView(value: min(max(value, 0), 1))
                .tint(colorForValue(value))
        }
    }

    private func colorForValue(_ value: Double) -> Color {
        if value > 0.9 { return .red }
        if value > 0.7 { return .orange }
        return .accentColor
    }
}
