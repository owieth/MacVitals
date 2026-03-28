import SwiftUI

struct RingGaugeView<Label: View>: View {
    let value: Double
    let lineWidth: CGFloat
    let gradient: AngularGradient
    @ViewBuilder let label: () -> Label

    init(
        value: Double,
        lineWidth: CGFloat = 6,
        gradient: AngularGradient,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.value = value
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.label = label
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.cardBorder, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedValue)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: clampedValue)

            label()
        }
    }

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }
}

extension RingGaugeView where Label == EmptyView {
    init(
        value: Double,
        lineWidth: CGFloat = 6,
        gradient: AngularGradient
    ) {
        self.value = value
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.label = { EmptyView() }
    }
}

enum RingGradients {
    static func forUsage(_ percentage: Double) -> AngularGradient {
        let color = Theme.Colors.forUsage(percentage)
        return AngularGradient(
            colors: [color.opacity(0.3), color],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    static let cpu = AngularGradient(
        colors: [
            Color(red: 0.82, green: 0.60, blue: 0.08).opacity(0.3),
            Color(red: 0.75, green: 0.12, blue: 0.06),
        ],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    static let memory = AngularGradient(
        colors: [Color.green.opacity(0.3), Color.green],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    static let gpu = AngularGradient(
        colors: [Color.purple.opacity(0.3), Color.purple],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    static let battery = AngularGradient(
        colors: [Color.green.opacity(0.3), Color.green],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    static let batteryLow = AngularGradient(
        colors: [Color.red.opacity(0.3), Color.red],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    static let batteryMedium = AngularGradient(
        colors: [Color.yellow.opacity(0.3), Color.yellow],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    static func batteryGradient(level: Double) -> AngularGradient {
        if level < 20 { return batteryLow }
        if level < 50 { return batteryMedium }
        return battery
    }
}
