import Foundation

final class ExternalIPFetcher: @unchecked Sendable {
    private(set) var cachedIP: String?
    private var lastFetch: Date?
    private var isFetching = false
    private let cacheDuration: TimeInterval = 300

    func fetchIfNeeded() {
        let now = Date()
        if let last = lastFetch, now.timeIntervalSince(last) < cacheDuration {
            return
        }
        guard !isFetching else { return }
        isFetching = true
        lastFetch = now

        let url = URL(string: "https://api.ipify.org")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            defer { self?.isFetching = false }
            guard error == nil,
                  let data,
                  let ip = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !ip.isEmpty else { return }
            self?.cachedIP = ip
        }
        task.resume()
    }
}
