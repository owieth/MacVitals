import Foundation

@MainActor
@Observable
class MenuBarViewModel {
    var snapshot: SystemSnapshot? {
        SystemMonitor.shared.snapshot
    }
}
