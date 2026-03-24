import SwiftUI

struct BluetoothSectionView: View {
    let devices: [BluetoothDeviceInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bluetooth")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)

            if devices.isEmpty {
                Text("No Bluetooth devices")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            } else {
                ForEach(devices) { device in
                    HStack(spacing: 10) {
                        Image(systemName: iconName(for: device.deviceType))
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.accentCyan)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(device.name)
                                .font(Theme.Fonts.dataValue)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .lineLimit(1)
                            Text(device.deviceType.rawValue)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        Spacer()

                        if let battery = device.batteryLevel {
                            HStack(spacing: 4) {
                                Image(systemName: batteryIcon(level: battery))
                                    .font(.system(size: 12))
                                    .foregroundStyle(batteryColor(level: battery))
                                Text("\(battery)%")
                                    .font(Theme.Fonts.dataValue)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func iconName(for type: BluetoothDeviceType) -> String {
        switch type {
        case .keyboard: return "keyboard"
        case .mouse: return "computermouse"
        case .trackpad: return "rectangle.and.hand.point.up.left"
        case .headphones: return "headphones"
        case .other: return "wave.3.right"
        }
    }

    private func batteryIcon(level: Int) -> String {
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }

    private func batteryColor(level: Int) -> Color {
        if level < 20 { return Theme.Colors.criticalRed }
        if level < 50 { return Theme.Colors.warningOrange }
        return Theme.Colors.nominalGreen
    }
}
