import SwiftUI

struct GPUSectionView: View {
    let gpu: GPUInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GPU")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: 12) {
                RingGaugeView(
                    value: gpu.utilizationPercentage / 100,
                    lineWidth: 5,
                    gradient: RingGradients.forUsage(gpu.utilizationPercentage)
                ) {
                    Text(Formatters.percentage(gpu.utilizationPercentage))
                        .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    if !gpu.name.isEmpty {
                        Text(gpu.name)
                            .font(Theme.Fonts.dataValue)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    StatLabel(title: "Utilization", value: Formatters.percentage(gpu.utilizationPercentage))
                    if let vramUsed = gpu.vramUsed, let vramTotal = gpu.vramTotal {
                        HStack(spacing: 16) {
                            StatLabel(title: "VRAM Used", value: Formatters.bytes(vramUsed))
                            StatLabel(title: "VRAM Total", value: Formatters.bytes(vramTotal))
                        }
                    }
                }
            }
        }
    }
}
