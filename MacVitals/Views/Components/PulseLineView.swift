import SwiftUI

struct PulseLineView: View {
    let data: [Double]
    let maxValue: Double
    let gradient: LinearGradient

    init(
        data: [Double],
        maxValue: Double = 100,
        gradient: LinearGradient = LinearGradient(
            colors: [Theme.Colors.accentCyan, .green],
            startPoint: .leading,
            endPoint: .trailing
        )
    ) {
        self.data = data
        self.maxValue = maxValue
        self.gradient = gradient
    }

    var body: some View {
        GeometryReader { geometry in
            if data.count > 1 {
                let points = buildPoints(in: geometry.size)

                ZStack {
                    fillPath(points: points)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.accentCyan.opacity(0.15),
                                    Theme.Colors.accentCyan.opacity(0.0),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    linePath(points: points)
                        .stroke(gradient, lineWidth: 1.5)
                        .shadow(color: Theme.Colors.accentCyan.opacity(0.4), radius: 3)
                }
            }
        }
    }

    private func buildPoints(in size: CGSize) -> [CGPoint] {
        let stepX = size.width / CGFloat(max(data.count - 1, 1))
        return data.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            let normalized = min(max(value / maxValue, 0), 1)
            let y = size.height - (CGFloat(normalized) * size.height)
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func fillPath(points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: first.x, y: maxY(points)))
            path.addLine(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.addLine(to: CGPoint(x: last.x, y: maxY(points)))
            path.closeSubpath()
        }
    }

    private func maxY(_ points: [CGPoint]) -> CGFloat {
        points.map(\.y).max() ?? 0
    }
}
