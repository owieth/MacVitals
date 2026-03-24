import SwiftUI

struct GradientBar: View {
    var body: some View {
        Theme.Gradients.statusBar
            .frame(height: 3)
            .clipShape(RoundedRectangle(cornerRadius: 1.5))
    }
}
