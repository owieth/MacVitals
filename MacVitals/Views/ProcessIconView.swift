import SwiftUI

struct ProcessIconView: View {
    let process: ProcessSnapshot

    var body: some View {
        Image(nsImage: ProcessIconCache.shared.icon(for: process))
            .resizable()
            .frame(width: 14, height: 14)
    }
}
