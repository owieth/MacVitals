import SwiftUI

struct MemorySectionView: View {
    let memory: MemoryInfo

    var body: some View {
        DisclosureGroup("Memory") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Formatters.bytes(memory.used)) / \(Formatters.bytes(memory.total))")
                        .font(.caption.monospacedDigit())
                    Spacer()
                    PressureBadge(pressure: memory.pressure)
                }

                HStack(spacing: 16) {
                    StatLabel(title: "Active", value: Formatters.bytes(memory.active))
                    StatLabel(title: "Wired", value: Formatters.bytes(memory.wired))
                    StatLabel(title: "Compressed", value: Formatters.bytes(memory.compressed))
                }

                if !memory.topProcesses.isEmpty {
                    Text("Top: " + memory.topProcesses.map { "\($0.name) \(Formatters.bytes($0.memoryBytes))" }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.top, 4)
        }
    }
}

struct PressureBadge: View {
    let pressure: MemoryPressure

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(backgroundColor)
                .frame(width: 6, height: 6)
            Text(pressure.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor.opacity(0.15))
        .foregroundStyle(backgroundColor)
        .clipShape(Capsule())
        .accessibilityLabel("Memory pressure")
        .accessibilityValue(pressure.rawValue)
    }

    private var backgroundColor: Color {
        switch pressure {
        case .nominal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
