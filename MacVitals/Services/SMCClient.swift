import Foundation
import IOKit
import os.log

class SMCClient {
    private static let logger = Logger(subsystem: "com.macvitals.app", category: "SMCClient")
    private var connection: io_connect_t = 0
    private var isOpen = false

    private static func emptySMCKeyData() -> SMCKeyData_t {
        var data = SMCKeyData_t()
        memset(&data, 0, MemoryLayout<SMCKeyData_t>.size)
        return data
    }

    func open() -> Bool {
        if isOpen { close() }
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault, IOServiceMatching("AppleSMC")
        )
        guard service != 0 else {
            Self.logger.error("Failed to find AppleSMC service")
            return false
        }
        let result = IOServiceOpen(service, mv_mach_task_self(), 0, &connection)
        IOObjectRelease(service)
        isOpen = result == KERN_SUCCESS
        if !isOpen {
            Self.logger.error("IOServiceOpen failed with result: \(result)")
        }
        return isOpen
    }

    func close() {
        if isOpen {
            IOServiceClose(connection)
            isOpen = false
        }
    }

    // MARK: - Type-aware value reading

    func readTemperature(key: String) -> Double? {
        guard let (bytes, dataType) = readKeyWithType(key: key) else { return nil }
        return decodeNumeric(bytes: bytes, dataType: dataType)
    }

    func readFanSpeed(index: Int) -> Int? {
        readFanValue(index: index, suffix: "Ac")
    }

    func readFanMin(index: Int) -> Int? {
        readFanValue(index: index, suffix: "Mn")
    }

    func readFanMax(index: Int) -> Int? {
        readFanValue(index: index, suffix: "Mx")
    }

    func readFanCount() -> Int {
        guard let (bytes, _) = readKeyWithType(key: "FNum") else { return 0 }
        guard !bytes.isEmpty else { return 0 }
        return Int(bytes[0])
    }

    private func readFanValue(index: Int, suffix: String) -> Int? {
        guard let (bytes, dataType) = readKeyWithType(key: "F\(index)\(suffix)") else { return nil }
        guard let value = decodeNumeric(bytes: bytes, dataType: dataType),
              value.isFinite, value >= 0, value < Double(Int.max) else { return nil }
        return Int(value)
    }

    // MARK: - Key enumeration

    func totalKeyCount() -> UInt32 {
        guard let (bytes, _) = readKeyWithType(key: "#KEY") else { return 0 }
        guard bytes.count >= 4 else { return 0 }
        return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) |
               (UInt32(bytes[2]) << 8)  | UInt32(bytes[3])
    }

    func keyAtIndex(_ index: UInt32) -> String? {
        guard isOpen else { return nil }

        var inputStruct = Self.emptySMCKeyData()
        var outputStruct = Self.emptySMCKeyData()

        inputStruct.data8 = 8 // kSMCGetKeyFromIndex
        inputStruct.data32 = index

        let inputSize = MemoryLayout<SMCKeyData_t>.size
        var outputSize = MemoryLayout<SMCKeyData_t>.size

        let result = IOConnectCallStructMethod(
            connection, 2,
            &inputStruct, inputSize,
            &outputStruct, &outputSize
        )

        guard result == KERN_SUCCESS else { return nil }

        let key = outputStruct.key
        let chars: [UInt8] = [
            UInt8((key >> 24) & 0xFF),
            UInt8((key >> 16) & 0xFF),
            UInt8((key >> 8) & 0xFF),
            UInt8(key & 0xFF),
        ]
        return String(bytes: chars, encoding: .ascii)
    }

    func discoverTemperatureKeys() -> [String] {
        let count = totalKeyCount()
        guard count > 0 else { return [] }

        var keys: [String] = []
        for i: UInt32 in 0..<count {
            guard let key = keyAtIndex(i) else { continue }
            guard key.first == "T" else { continue }
            if let temp = readTemperature(key: key), temp > 0, temp < 150 {
                keys.append(key)
            }
        }
        Self.logger.info("Discovered \(keys.count) temperature keys")
        return keys
    }

    // MARK: - Low-level SMC access

    private func getKeyInfo(key: UInt32) -> SMCKeyData_keyInfo_t? {
        guard isOpen else { return nil }

        var inputStruct = Self.emptySMCKeyData()
        var outputStruct = Self.emptySMCKeyData()

        inputStruct.key = key
        inputStruct.data8 = 9 // kSMCGetKeyInfo

        let inputSize = MemoryLayout<SMCKeyData_t>.size
        var outputSize = MemoryLayout<SMCKeyData_t>.size

        let result = IOConnectCallStructMethod(
            connection, 2,
            &inputStruct, inputSize,
            &outputStruct, &outputSize
        )

        guard result == KERN_SUCCESS else {
            Self.logger.debug("getKeyInfo failed for key \(key) with result: \(result)")
            return nil
        }
        return outputStruct.keyInfo
    }

    private func readKeyWithType(key: String) -> (bytes: [UInt8], dataType: UInt32)? {
        guard isOpen else { return nil }

        let keyUInt32 = stringToUInt32(key)

        guard let keyInfo = getKeyInfo(key: keyUInt32) else {
            Self.logger.debug("getKeyInfo failed for '\(key)'")
            return nil
        }

        var inputStruct = Self.emptySMCKeyData()
        var outputStruct = Self.emptySMCKeyData()

        inputStruct.key = keyUInt32
        inputStruct.data8 = 5 // kSMCReadKey
        inputStruct.keyInfo = keyInfo

        let inputSize = MemoryLayout<SMCKeyData_t>.size
        var outputSize = MemoryLayout<SMCKeyData_t>.size

        let result = IOConnectCallStructMethod(
            connection, 2,
            &inputStruct, inputSize,
            &outputStruct, &outputSize
        )

        guard result == KERN_SUCCESS else {
            Self.logger.debug("readKey failed for '\(key)' with result: \(result)")
            return nil
        }

        let bytes: [UInt8] = withUnsafeBytes(of: outputStruct.bytes) {
            Array($0.prefix(Int(keyInfo.dataSize)))
        }
        return (bytes, keyInfo.dataType)
    }

    // MARK: - Data type decoding

    /// Decode SMC numeric value based on its data type
    private func decodeNumeric(bytes: [UInt8], dataType: UInt32) -> Double? {
        let typeStr = uint32ToString(dataType)

        switch typeStr {
        case "sp78":
            // Signed 8.8 fixed-point (e.g. temperature)
            guard bytes.count >= 2 else { return nil }
            let raw = Int16(Int16(bytes[0]) << 8 | Int16(bytes[1]))
            return Double(raw) / 256.0

        case "fpe2":
            // Unsigned 14.2 fixed-point (e.g. fan RPM on Intel)
            guard bytes.count >= 2 else { return nil }
            let raw = (UInt(bytes[0]) << 8) | UInt(bytes[1])
            return Double(raw) / 4.0

        case "flt ":
            // IEEE 754 single-precision float, little-endian (Apple Silicon)
            guard bytes.count >= 4 else { return nil }
            let bits = UInt32(bytes[0]) | UInt32(bytes[1]) << 8 |
                       UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
            return Double(Float(bitPattern: bits))

        case "ioft":
            // IOKit float — 8 bytes, little-endian IEEE 754 double or float in first 4 bytes
            if bytes.count >= 8 {
                let bits = UInt64(bytes[0]) | UInt64(bytes[1]) << 8 |
                           UInt64(bytes[2]) << 16 | UInt64(bytes[3]) << 24 |
                           UInt64(bytes[4]) << 32 | UInt64(bytes[5]) << 40 |
                           UInt64(bytes[6]) << 48 | UInt64(bytes[7]) << 56
                return Double(bitPattern: bits)
            }
            return nil

        case "ui8 ":
            guard !bytes.isEmpty else { return nil }
            return Double(bytes[0])

        case "ui16":
            guard bytes.count >= 2 else { return nil }
            return Double((UInt16(bytes[0]) << 8) | UInt16(bytes[1]))

        case "ui32":
            guard bytes.count >= 4 else { return nil }
            let val = UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 |
                      UInt32(bytes[2]) << 8  | UInt32(bytes[3])
            return Double(val)

        case "si16":
            guard bytes.count >= 2 else { return nil }
            let raw = Int16(Int16(bytes[0]) << 8 | Int16(bytes[1]))
            return Double(raw)

        default:
            // Unknown type — try sp78 as fallback for temperature-like 2-byte values
            if bytes.count == 2 {
                let raw = Int16(Int16(bytes[0]) << 8 | Int16(bytes[1]))
                return Double(raw) / 256.0
            }
            return nil
        }
    }

    private func stringToUInt32(_ str: String) -> UInt32 {
        var result: UInt32 = 0
        for (i, char) in str.utf8.prefix(4).enumerated() {
            result |= UInt32(char) << (24 - 8 * i)
        }
        return result
    }

    private func uint32ToString(_ val: UInt32) -> String {
        let chars: [UInt8] = [
            UInt8((val >> 24) & 0xFF),
            UInt8((val >> 16) & 0xFF),
            UInt8((val >> 8) & 0xFF),
            UInt8(val & 0xFF),
        ]
        return String(bytes: chars, encoding: .ascii) ?? ""
    }
}
