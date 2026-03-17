import SwiftUI

struct NetworkSectionView: View {
    let network: NetworkInfo

    var body: some View {
        DisclosureGroup("Network") {
            VStack(alignment: .leading, spacing: 8) {
                if !network.interfaceName.isEmpty {
                    HStack {
                        Text(network.interfaceName)
                            .font(.caption.monospacedDigit())
                        Spacer()
                        Text(network.ipAddress)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    StatLabel(title: "↓ Download", value: Formatters.bytesPerSecond(network.downloadBytesPerSec))
                    StatLabel(title: "↑ Upload", value: Formatters.bytesPerSecond(network.uploadBytesPerSec))
                }

                if network.interfaceName.isEmpty {
                    Text("No active connection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }
}
