import Foundation
import IOKit
import os.log

struct SMCKeyData {
    struct Version {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    struct PLimitData {
        var version: UInt16 = 0
        var length: UInt16 = 0
        var cpuPLimit: UInt32 = 0
        var gpuPLimit: UInt32 = 0
        var memPLimit: UInt32 = 0
    }

    struct KeyInfo {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
    }

    var key: UInt32 = 0
    var vers = Version()
    var pLimitData = PLimitData()
    var keyInfo = KeyInfo()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

class SMCClient {
    private static let logger = Logger(subsystem: "com.macvitals.app", category: "SMCClient")
    private var connection: io_connect_t = 0
    private var isOpen = false

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

    func readTemperature(key: String) -> Double? {
        guard let bytes = readKey(key: key, dataSize: 2) else { return nil }
        let value = (Int(bytes[0]) << 8) | Int(bytes[1])
        return Double(value) / 256.0
    }

    func readFanSpeed(index: Int) -> Int? {
        readFPE2(index: index, suffix: "Ac")
    }

    func readFanMin(index: Int) -> Int? {
        readFPE2(index: index, suffix: "Mn")
    }

    func readFanMax(index: Int) -> Int? {
        readFPE2(index: index, suffix: "Mx")
    }

    private func readFPE2(index: Int, suffix: String) -> Int? {
        guard let bytes = readKey(key: "F\(index)\(suffix)", dataSize: 2) else { return nil }
        let value = (UInt(bytes[0]) << 8) | UInt(bytes[1])
        return Int(value >> 2)
    }

    func readFanCount() -> Int {
        guard let bytes = readKey(key: "FNum", dataSize: 1) else { return 0 }
        return Int(bytes[0])
    }

    private func readKey(key: String, dataSize: UInt32) -> [UInt8]? {
        guard isOpen else { return nil }

        var inputStruct = SMCKeyData()
        var outputStruct = SMCKeyData()

        inputStruct.key = stringToUInt32(key)
        let kSMCReadKey: UInt8 = 5
        inputStruct.data8 = kSMCReadKey
        inputStruct.keyInfo.dataSize = dataSize

        let inputSize = MemoryLayout<SMCKeyData>.size
        var outputSize = MemoryLayout<SMCKeyData>.size

        let result = IOConnectCallStructMethod(
            connection,
            2, // kSMCHandleYPCEvent
            // selector for SMC read/write operations
            &inputStruct,
            inputSize,
            &outputStruct,
            &outputSize
        )

        guard result == KERN_SUCCESS else { return nil }

        return withUnsafeBytes(of: outputStruct.bytes) {
            Array($0.prefix(Int(dataSize)))
        }
    }

    private func stringToUInt32(_ str: String) -> UInt32 {
        var result: UInt32 = 0
        for (i, char) in str.utf8.prefix(4).enumerated() {
            result |= UInt32(char) << (24 - 8 * i)
        }
        return result
    }
}
