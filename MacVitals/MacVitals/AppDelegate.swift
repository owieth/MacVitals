import SwiftUI
import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var isQuittingFromMenu = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "gauge.with.dots.needle.bottom.50percent",
                accessibilityDescription: "MacVitals"
            )
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 420, height: 550)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(UserPreferences.shared)
        )

        NSApp.setActivationPolicy(.accessory)

        SystemMonitor.shared.start()
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        guard let button = statusItem?.button else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(
                NSMenuItem(
                    title: "Settings...",
                    action: #selector(openSettings),
                    keyEquivalent: ","
                )
            )
            menu.addItem(NSMenuItem.separator())
            menu.addItem(
                NSMenuItem(
                    title: "Quit MacVitals",
                    action: #selector(quitApp),
                    keyEquivalent: "q"
                )
            )

            statusItem?.menu = menu
            button.performClick(nil)
            statusItem?.menu = nil
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func openSettings() {
        WindowManager.shared.openSettingsWindow()
    }

    @objc private func quitApp() {
        isQuittingFromMenu = true
        NSApp.terminate(nil)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if isQuittingFromMenu {
            return .terminateNow
        }

        let alert = NSAlert()
        alert.messageText = "Quit MacVitals?"
        alert.informativeText =
            "MacVitals runs in the menu bar to monitor your system. Use the menu bar icon's right-click menu to quit."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Keep Running")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            return .terminateNow
        }
        return .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        SystemMonitor.shared.stop()
    }
}
