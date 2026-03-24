import SwiftUI

struct StorageSectionView: View {
    let storage: StorageInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Storage")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack {
                Text("\(Formatters.bytesDecimal(storage.used)) / \(Formatters.bytesDecimal(storage.total))")
                    .font(Theme.Fonts.dataValue)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Text(Formatters.percentage(storage.usagePercentage))
                    .font(Theme.Fonts.dataValue)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            SegmentedBar(fraction: storage.usagePercentage / 100)
                .frame(height: 8)
                .accessibilityLabel("Storage usage")
                .accessibilityValue(Formatters.percentage(storage.usagePercentage))

            HStack(spacing: 16) {
                StatLabel(title: "Read", value: Formatters.bytesPerSecond(storage.readBytesPerSec))
                StatLabel(title: "Write", value: Formatters.bytesPerSecond(storage.writeBytesPerSec))
            }
        }
    }
}

private struct SegmentedBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Colors.cardBorder)

                RoundedRectangle(cornerRadius: 4)
                    .fill(barGradient)
                    .frame(width: max(geometry.size.width * clampedFraction, 4))
            }
        }
    }

    private var clampedFraction: CGFloat {
        CGFloat(min(max(fraction, 0), 1))
    }

    private var barGradient: LinearGradient {
        let color = Theme.Colors.forUsage(fraction * 100)
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
