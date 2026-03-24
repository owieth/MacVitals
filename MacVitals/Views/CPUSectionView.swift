import SwiftUI

struct CPUSectionView: View {
    let cpu: CPUInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CPU")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: 16) {
                StatLabel(title: "Total", value: Formatters.percentage(cpu.totalUsage))
                StatLabel(title: "User", value: Formatters.percentage(cpu.userUsage))
                StatLabel(title: "System", value: Formatters.percentage(cpu.systemUsage))
            }

            if !cpu.coreUsages.isEmpty {
                VStack(spacing: 3) {
                    ForEach(Array(cpu.coreUsages.enumerated()), id: \.offset) { index, usage in
                        CoreBarRow(index: index, usage: usage)
                    }
                }
            }

            if !cpu.topProcesses.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(cpu.topProcesses, id: \.pid) { process in
                            HStack {
                                Text(process.name)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(Formatters.percentage(process.cpuUsage))
                                    .font(Theme.Fonts.caption.monospacedDigit())
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                        }
                    }
                } label: {
                    Text("Top Processes")
                        .font(Theme.Fonts.dataLabel)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .tint(Theme.Colors.textTertiary)
            }
        }
    }
}

private struct CoreBarRow: View {
    let index: Int
    let usage: Double

    var body: some View {
        HStack(spacing: 6) {
            Text("\(index)")
                .font(Theme.Fonts.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 18, alignment: .trailing)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.cardBorder)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(barGradient)
                        .frame(width: max(geometry.size.width * clampedFraction, 2), height: 6)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 10)

            Text(Formatters.percentage(usage))
                .font(Theme.Fonts.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 32, alignment: .trailing)
        }
        .accessibilityLabel("Core \(index)")
        .accessibilityValue(Formatters.percentage(usage))
    }

    private var clampedFraction: CGFloat {
        CGFloat(min(max(usage / 100, 0), 1))
    }

    private var barGradient: LinearGradient {
        let color = Theme.Colors.forUsage(usage)
        return LinearGradient(
            colors: [color.opacity(0.6), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct StatLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.Fonts.dataLabel)
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(value)
                .font(Theme.Fonts.dataValue)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}
