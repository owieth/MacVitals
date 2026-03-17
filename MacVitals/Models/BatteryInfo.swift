import Foundation

struct BatteryInfo {
    let level: Double
    let health: Double
    let cycleCount: Int
    let isCharging: Bool
    let isPluggedIn: Bool
    let timeRemaining: TimeInterval?
    let temperature: Double?

    static let empty = BatteryInfo(
        level: 0,
        health: 0,
        cycleCount: 0,
        isCharging: false,
        isPluggedIn: false,
        timeRemaining: nil,
        temperature: nil
    )
}
