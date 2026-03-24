import SwiftUI
import Charts

struct HistoryChartView: View {
    let title: String
    let data: [Double]
    let color: Color
    let unit: String
    let maxValue: Double?

    init(title: String, data: [Double], color: Color, unit: String = "%", maxValue: Double? = nil) {
        self.title = title
        self.data = data
        self.color = color
        self.unit = unit
        self.maxValue = maxValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(Theme.Fonts.sectionTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                if let last = data.last {
                    Text(formatValue(last))
                        .font(Theme.Fonts.dataValue)
                        .foregroundStyle(color)
                }
            }

            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", index),
                        y: .value(title, value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", index),
                        y: .value(title, value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Theme.Colors.cardBorder)
                    AxisValueLabel()
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .chartYScale(domain: 0...(computedMax))
            .frame(height: 80)
        }
    }

    private var computedMax: Double {
        if let maxValue { return maxValue }
        let dataMax = data.max() ?? 100
        return max(dataMax * 1.1, 1)
    }

    private func formatValue(_ value: Double) -> String {
        if unit == "%" {
            return Formatters.percentage(value)
        }
        if unit == "B/s" {
            return Formatters.bytesPerSecond(UInt64(value))
        }
        return String(format: "%.0f%@", value, unit)
    }
}
