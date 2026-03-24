import Foundation
import IOKit
import os.log

struct BluetoothCollector {
    private static let logger = Logger(subsystem: "com.macvitals.app", category: "BluetoothCollector")

    func collect() -> [BluetoothDeviceInfo] {
        var devices: [BluetoothDeviceInfo] = []

        let matching = IOServiceMatching("AppleDeviceManagementHIDEventService")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return collectFromBluetooth()
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var props: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = props?.takeRetainedValue() as? [String: Any] else { continue }

            let product = dict["Product"] as? String ?? ""
            guard !product.isEmpty else { continue }

            let battery = dict["BatteryPercent"] as? Int
            let address = dict["SerialNumber"] as? String
                ?? dict["DeviceAddress"] as? String
                ?? UUID().uuidString

            let deviceType = classifyDevice(name: product)

            devices.append(BluetoothDeviceInfo(
                id: address,
                name: product,
                batteryLevel: battery,
                isConnected: true,
                deviceType: deviceType
            ))
        }

        if devices.isEmpty {
            return collectFromBluetooth()
        }
        return devices
    }

    private func collectFromBluetooth() -> [BluetoothDeviceInfo] {
        var devices: [BluetoothDeviceInfo] = []

        let matching = IOServiceMatching("IOBluetoothDevice")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return devices
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var props: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = props?.takeRetainedValue() as? [String: Any] else { continue }

            let name = dict["Name"] as? String ?? ""
            guard !name.isEmpty else { continue }

            let battery = dict["BatteryPercent"] as? Int
            let address = dict["BD_ADDR"] as? String ?? UUID().uuidString
            let connected = dict["ClassOfDevice"] as? Int != nil

            devices.append(BluetoothDeviceInfo(
                id: address,
                name: name,
                batteryLevel: battery,
                isConnected: connected,
                deviceType: classifyDevice(name: name)
            ))
        }

        return devices
    }

    private func classifyDevice(name: String) -> BluetoothDeviceType {
        let lower = name.lowercased()
        if lower.contains("keyboard") { return .keyboard }
        if lower.contains("mouse") { return .mouse }
        if lower.contains("trackpad") { return .trackpad }
        if lower.contains("airpod") || lower.contains("headphone") || lower.contains("beats") {
            return .headphones
        }
        return .other
    }
}
