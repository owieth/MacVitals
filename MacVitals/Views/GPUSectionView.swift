import SwiftUI

struct GPUSectionView: View {
    let gpu: GPUInfo

    var body: some View {
        DisclosureGroup("GPU") {
            VStack(alignment: .leading, spacing: 8) {
                if !gpu.name.isEmpty {
                    Text(gpu.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Utilization")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Formatters.percentage(gpu.utilizationPercentage))
                        .font(.caption.monospacedDigit())
                }

                ProgressView(value: min(max(gpu.utilizationPercentage / 100, 0), 1))
                    .tint(gpu.utilizationPercentage > 90 ? .red : gpu.utilizationPercentage > 70 ? .orange : .accentColor)
                    .accessibilityLabel("GPU utilization")
                    .accessibilityValue(Formatters.percentage(gpu.utilizationPercentage))
            }
            .padding(.top, 4)
        }
    }
}
