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
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(max(data.count - 1, 1))

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = min(max(value / maxValue, 0), 1)
                        let y = height - (CGFloat(normalized) * height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 1.5)
            }
        }
    }
}
