import SwiftUI

struct CPUSectionView: View {
    let cpu: CPUInfo

    private var useGrid: Bool { cpu.coreUsages.count > 8 }

    var body: some View {
        DisclosureGroup("CPU") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    StatLabel(title: "Total", value: Formatters.percentage(cpu.totalUsage))
                    StatLabel(title: "User", value: Formatters.percentage(cpu.userUsage))
                    StatLabel(title: "System", value: Formatters.percentage(cpu.systemUsage))
                }

                if !cpu.coreUsages.isEmpty {
                    coreUsagesView
                }

                if !cpu.topProcesses.isEmpty {
                    Text("Top: " + cpu.topProcesses.map { "\($0.name) \(Formatters.percentage($0.cpuUsage))" }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var coreUsagesView: some View {
        if useGrid {
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(cpu.coreUsages.enumerated()), id: \.offset) { index, usage in
                    coreBar(index: index, usage: usage)
                }
            }
        } else {
            VStack(spacing: 2) {
                ForEach(Array(cpu.coreUsages.enumerated()), id: \.offset) { index, usage in
                    coreBar(index: index, usage: usage)
                }
            }
        }
    }

    private func coreBar(index: Int, usage: Double) -> some View {
        HStack(spacing: 4) {
            Text("\(index)")
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)
            ProgressView(value: min(max(usage / 100, 0), 1))
                .tint(coreColor(usage))
            Text(Formatters.percentage(usage))
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func coreColor(_ usage: Double) -> Color {
        if usage > 90 { return .red }
        if usage > 70 { return .orange }
        return .accentColor
    }
}

struct StatLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }
}
