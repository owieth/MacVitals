import Foundation
import AppKit

enum Constants {
    static let defaultRefreshInterval: TimeInterval = 2.0
    static let popoverWidth: CGFloat = 420
    static let popoverHeight: CGFloat = 550
    static let appName = "MacVitals"
    static let githubURL = "https://github.com/owieth/MacVitals"

    static func openGitHub() {
        if let url = URL(string: githubURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
