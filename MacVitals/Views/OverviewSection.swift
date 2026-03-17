import SwiftUI

struct OverviewSection: View {
    let snapshot: SystemSnapshot?
    var cpuHistory: [Double] = []
    var memoryHistory: [Double] = []

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

                if !cpuHistory.isEmpty || !memoryHistory.isEmpty {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CPU")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                            SparklineView(data: cpuHistory, color: .blue)
                                .frame(height: 24)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Memory")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                            SparklineView(data: memoryHistory, color: .green)
                                .frame(height: 24)
                        }
                    }
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
                .accessibilityLabel("\(label) usage")
                .accessibilityValue(displayValue)
        }
    }

    private func colorForValue(_ value: Double) -> Color {
        .forUsage(value * 100)
    }
}

extension Color {
    static func forUsage(_ percentage: Double) -> Color {
        if percentage > 90 { return .red }
        if percentage > 70 { return .orange }
        return .accentColor
    }
}
