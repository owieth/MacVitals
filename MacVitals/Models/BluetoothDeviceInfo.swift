import Foundation

enum BluetoothDeviceType: String {
    case keyboard = "Keyboard"
    case mouse = "Mouse"
    case trackpad = "Trackpad"
    case headphones = "Headphones"
    case other = "Device"
}

struct BluetoothDeviceInfo: Identifiable {
    let id: String
    let name: String
    let batteryLevel: Int?
    let isConnected: Bool
    let deviceType: BluetoothDeviceType
}
