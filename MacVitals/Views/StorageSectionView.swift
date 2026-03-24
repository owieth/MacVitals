import SwiftUI

struct StorageSectionView: View {
    let storage: StorageInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Storage")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Formatters.bytesDecimal(storage.used)) / \(Formatters.bytesDecimal(storage.total))")
                        .font(.caption.monospacedDigit())
                    Spacer()
                    Text(Formatters.percentage(storage.usagePercentage))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: min(max(storage.usagePercentage / 100, 0), 1))
                    .tint(.forUsage(storage.usagePercentage))
                    .accessibilityLabel("Storage usage")
                    .accessibilityValue(Formatters.percentage(storage.usagePercentage))

                HStack(spacing: 16) {
                    StatLabel(title: "Read", value: Formatters.bytesPerSecond(storage.readBytesPerSec))
                    StatLabel(title: "Write", value: Formatters.bytesPerSecond(storage.writeBytesPerSec))
                }
            }
        }
    }
}
