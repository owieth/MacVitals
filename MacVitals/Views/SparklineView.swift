import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let maxValue: Double
    let color: Color

    init(data: [Double], maxValue: Double = 100, color: Color = .accentColor) {
        self.data = data
        self.maxValue = maxValue
        self.color = color
    }

    var body: some View {
        GeometryReader { geometry in
            if data.count > 1 {
                let points = buildPoints(in: geometry.size)

                ZStack {
                    fillPath(points: points, height: geometry.size.height)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    linePath(points: points)
                        .stroke(color, lineWidth: 1.5)
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

    private func fillPath(points: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
    }
}
