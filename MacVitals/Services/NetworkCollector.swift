import Foundation
import Darwin

struct NetworkCollector {
    private var previousUploadBytes: UInt64 = 0
    private var previousDownloadBytes: UInt64 = 0
    private var previousTimestamp: Date?

    mutating func collect() -> NetworkInfo {
        let (interfaceName, ipAddress) = activeInterface()
        let (uploadBytes, downloadBytes) = totalBytes()

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
            ipAddress: ipAddress
        )
    }

    private func activeInterface() -> (name: String, ip: String) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return ("", "") }
        defer { freeifaddrs(ifaddr) }

        var bestName = ""
        var bestIP = ""

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_RUNNING != 0, flags & IFF_LOOPBACK == 0 else { continue }
            guard let addr = ptr.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: ptr.pointee.ifa_name)
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: hostname)
                if name.hasPrefix("en") {
                    return (name, ip)
                }
                if bestName.isEmpty {
                    bestName = name
                    bestIP = ip
                }
            }
        }
        return (bestName, bestIP)
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
