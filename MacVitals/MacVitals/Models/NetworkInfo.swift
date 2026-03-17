import Foundation

struct NetworkInfo {
    let uploadBytesPerSec: UInt64
    let downloadBytesPerSec: UInt64
    let interfaceName: String
    let ipAddress: String

    static let empty = NetworkInfo(
        uploadBytesPerSec: 0,
        downloadBytesPerSec: 0,
        interfaceName: "",
        ipAddress: ""
    )
}
