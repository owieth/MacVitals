import Foundation
import Darwin

struct NetworkCollector {
    private var previousUploadBytes: UInt64 = 0
    private var previousDownloadBytes: UInt64 = 0
    private var previousTimestamp: Date?
    var cachedExternalIP: String?
    private var externalIPFetcher = ExternalIPFetcher()

    mutating func collect() -> NetworkInfo {
        let (interfaceName, ipAddress, macAddress) = activeInterface()
        let (uploadBytes, downloadBytes) = totalBytes()
        let gatewayIP = Self.readGatewayIP()

        var uploadPerSec: UInt64 = 0
        var downloadPerSec: UInt64 = 0
        let now = Date()
        if let prev = previousTimestamp {
            let elapsed = now.timeIntervalSince(prev)
            if elapsed > 0, uploadBytes >= previousUploadBytes, downloadBytes >= previousDownloadBytes {
                uploadPerSec = UInt64(Double(uploadBytes - previousUploadBytes) / elapsed)
                downloadPerSec = UInt64(Double(downloadBytes - previousDownloadBytes) / elapsed)
            }
        }
        previousUploadBytes = uploadBytes
        previousDownloadBytes = downloadBytes
        previousTimestamp = now

        return NetworkInfo(
            uploadBytesPerSec: uploadPerSec,
            downloadBytesPerSec: downloadPerSec,
            interfaceName: interfaceName,
            ipAddress: ipAddress,
            gatewayIP: gatewayIP,
            macAddress: macAddress,
            externalIP: cachedExternalIP
        )
    }

    mutating func fetchExternalIPIfNeeded() {
        externalIPFetcher.fetchIfNeeded()
        cachedExternalIP = externalIPFetcher.cachedIP
    }

    private func activeInterface() -> (name: String, ip: String, mac: String) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return ("", "", "") }
        defer { freeifaddrs(ifaddr) }

        var bestName = ""
        var bestIP = ""
        var bestMAC = ""

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_RUNNING != 0, flags & IFF_LOOPBACK == 0 else { continue }
            guard let addr = ptr.pointee.ifa_addr else { continue }
            let name = String(cString: ptr.pointee.ifa_name)

            if addr.pointee.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ip = String(cString: hostname)
                    if name.hasPrefix("en") {
                        let mac = Self.macAddress(for: name, firstAddr: firstAddr)
                        return (name, ip, mac)
                    }
                    if bestName.isEmpty {
                        bestName = name
                        bestIP = ip
                    }
                }
            }
        }

        if !bestName.isEmpty {
            bestMAC = Self.macAddress(for: bestName, firstAddr: firstAddr)
        }
        return (bestName, bestIP, bestMAC)
    }

    private static func macAddress(for interfaceName: String, firstAddr: UnsafeMutablePointer<ifaddrs>) -> String {
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let name = String(cString: ptr.pointee.ifa_name)
            guard name == interfaceName,
                  let addr = ptr.pointee.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_LINK) else { continue }

            let sdl = addr.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { $0.pointee }
            guard sdl.sdl_alen == 6 else { continue }

            var macBytes = [UInt8](repeating: 0, count: 6)
            let nlen = Int(sdl.sdl_nlen)
            withUnsafePointer(to: sdl.sdl_data) { dataPtr in
                dataPtr.withMemoryRebound(to: CChar.self, capacity: nlen + 6) { ptr in
                    for i in 0..<6 {
                        macBytes[i] = UInt8(bitPattern: ptr[nlen + i])
                    }
                }
            }
            return macBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
        }
        return ""
    }

    private static func readGatewayIP() -> String {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        process.arguments = ["-rn"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return "" }

        for line in output.components(separatedBy: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 2 else { continue }
            if parts[0] == "default" {
                return String(parts[1])
            }
        }
        return ""
    }

    private func totalBytes() -> (upload: UInt64, download: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }

        var totalUp: UInt64 = 0
        var totalDown: UInt64 = 0

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }
            guard let addr = ptr.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) else { continue }

            let data = unsafeBitCast(ptr.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            totalUp += UInt64(data.pointee.ifi_obytes)
            totalDown += UInt64(data.pointee.ifi_ibytes)
        }

        return (totalUp, totalDown)
    }
}
