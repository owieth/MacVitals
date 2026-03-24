import SwiftUI

struct NetworkSectionView: View {
    let network: NetworkInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Network")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)

            if !network.interfaceName.isEmpty {
                HStack {
                    Text(network.interfaceName)
                        .font(Theme.Fonts.dataValue)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    if !network.macAddress.isEmpty {
                        Text(network.macAddress)
                            .font(Theme.Fonts.caption.monospacedDigit())
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    networkRow(label: "IP", value: network.ipAddress)
                    if !network.gatewayIP.isEmpty {
                        networkRow(label: "Gateway", value: network.gatewayIP)
                    }
                    if let externalIP = network.externalIP {
                        networkRow(label: "External", value: externalIP)
                    }
                }
            }

            HStack(spacing: 16) {
                StatLabel(title: "↓ Download", value: Formatters.bytesPerSecond(network.downloadBytesPerSec))
                StatLabel(title: "↑ Upload", value: Formatters.bytesPerSecond(network.uploadBytesPerSec))
            }

            if network.interfaceName.isEmpty {
                Text("No active connection")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
    }

    private func networkRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.dataLabel)
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 55, alignment: .leading)
            Text(value)
                .font(Theme.Fonts.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}
