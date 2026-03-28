import SwiftUI

enum Theme {

    enum Colors {
        static let backgroundDark = Color(red: 0.04, green: 0.02, blue: 0.01)
        static let backgroundNavy = Color(red: 0.09, green: 0.05, blue: 0.03)
        static let cardBackground = Color.white.opacity(0.05)
        static let cardBorder = Color.white.opacity(0.08)

        static let accentCyan = Color(red: 0.82, green: 0.52, blue: 0.08)
        static let warningOrange = Color(red: 0.90, green: 0.38, blue: 0.08)
        static let criticalRed = Color(red: 0.78, green: 0.12, blue: 0.06)
        static let nominalGreen = Color.green

        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.6)
        static let textTertiary = Color.white.opacity(0.35)

        static func forUsage(_ percentage: Double) -> Color {
            if percentage > 90 { return criticalRed }
            if percentage > 70 { return warningOrange }
            return accentCyan
        }
    }

    enum Gradients {
        static let background = RadialGradient(
            colors: [Colors.backgroundNavy, Colors.backgroundDark],
            center: .center,
            startRadius: 0,
            endRadius: 400
        )

        static let statusBar = LinearGradient(
            colors: [
                Color(red: 0.82, green: 0.60, blue: 0.08),
                Color(red: 0.80, green: 0.32, blue: 0.08),
                Color(red: 0.75, green: 0.12, blue: 0.06),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    enum Spacing {
        static let cardPadding: CGFloat = 12
        static let cardCornerRadius: CGFloat = 12
        static let sectionSpacing: CGFloat = 12
        static let contentPadding: CGFloat = 16
    }

    enum Fonts {
        static let sectionTitle = Font.system(size: 13, weight: .semibold, design: .rounded)
        static let dataValue = Font.system(size: 12, weight: .medium, design: .default).monospacedDigit()
        static let dataLabel = Font.system(size: 10, weight: .regular, design: .default)
        static let caption = Font.system(size: 9, weight: .regular, design: .default)
    }
}
