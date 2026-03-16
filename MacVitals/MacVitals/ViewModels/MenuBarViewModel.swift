import Foundation
import Combine

@MainActor
@Observable
class MenuBarViewModel {
    var snapshot: SystemSnapshot?

    private var cancellable: AnyCancellable?

    init() {
        cancellable = SystemMonitor.shared.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] newSnapshot in
                self?.snapshot = newSnapshot
            }
    }
}
