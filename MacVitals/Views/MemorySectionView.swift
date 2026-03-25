import SwiftUI

struct MemorySectionView: View {
    let memory: MemoryInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Memory")
                    .font(Theme.Fonts.sectionTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                PressureBadge(pressure: memory.pressure)
            }

            HStack(spacing: 12) {
                MemoryRing(memory: memory)
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(Formatters.bytes(memory.used)) / \(Formatters.bytes(memory.total))")
                        .font(Theme.Fonts.dataValue)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    HStack(spacing: 12) {
                        MemoryLegendItem(color: .blue, label: "Active", value: Formatters.bytes(memory.active))
                        MemoryLegendItem(color: .orange, label: "Wired", value: Formatters.bytes(memory.wired))
                        MemoryLegendItem(color: .purple, label: "Comp.", value: Formatters.bytes(memory.compressed))
                    }
                }
            }

            if !memory.topProcesses.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(memory.topProcesses, id: \.pid) { process in
                            HStack {
                                ProcessIconView(process: process)
                                Text(process.name)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(Formatters.bytes(process.memoryBytes))
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

private struct MemoryRing: View {
    let memory: MemoryInfo

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.cardBorder, lineWidth: 5)

            segmentArc(from: 0, to: activeFraction, color: .blue)
            segmentArc(from: activeFraction, to: activeFraction + wiredFraction, color: .orange)
            segmentArc(from: activeFraction + wiredFraction, to: activeFraction + wiredFraction + compressedFraction, color: .purple)

            Text(Formatters.percentage(memory.usagePercentage))
                .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private func segmentArc(from: Double, to: Double, color: Color) -> some View {
        Circle()
            .trim(from: from, to: min(to, 1))
            .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .butt))
            .rotationEffect(.degrees(-90))
    }

    private var totalBytes: Double { max(Double(memory.total), 1) }
    private var activeFraction: Double { Double(memory.active) / totalBytes }
    private var wiredFraction: Double { Double(memory.wired) / totalBytes }
    private var compressedFraction: Double { Double(memory.compressed) / totalBytes }
}

private struct MemoryLegendItem: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                Text(label)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            Text(value)
                .font(Theme.Fonts.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

struct PressureBadge: View {
    let pressure: MemoryPressure

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 6, height: 6)
            Text(pressure.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.15))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
        .accessibilityLabel("Memory pressure")
        .accessibilityValue(pressure.rawValue)
    }

    private var badgeColor: Color {
        switch pressure {
        case .nominal: return Theme.Colors.nominalGreen
        case .warning: return Theme.Colors.warningOrange
        case .critical: return Theme.Colors.criticalRed
        }
    }
}
