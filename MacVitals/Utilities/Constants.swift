import Foundation
import AppKit

enum Constants {
    static let popoverWidth: CGFloat = 460
    static let popoverHeight: CGFloat = 620
    static let appName = "MacVitals"
    static let githubURL = "https://github.com/owieth/MacVitals"

    static func openGitHub() {
        if let url = URL(string: githubURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
