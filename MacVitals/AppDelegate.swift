import SwiftUI
import AppKit
import Combine
import Carbon.HIToolbox

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var isQuittingFromMenu = false
    private var cancellable: AnyCancellable?

    private func makeStatusBarIcon() -> NSImage? {
        guard let appIcon = NSImage(named: "AppIcon") else { return nil }
        let size = NSSize(width: 18, height: 18)
        let resized = NSImage(size: size)
        resized.lockFocus()
        appIcon.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: appIcon.size),
            operation: .copy,
            fraction: 1.0
        )
        resized.unlockFocus()
        resized.isTemplate = false
        return resized
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = makeStatusBarIcon()
            button.imagePosition = .imageLeading
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(
            width: Constants.popoverWidth,
            height: Constants.popoverHeight
        )
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(UserPreferences.shared)
        )

        NSApp.setActivationPolicy(.accessory)

        SystemMonitor.shared.start()

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.option, .shift]) && event.keyCode == 9 {
                Task { @MainActor in
                    self?.togglePopover()
                }
            }
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.option, .shift]) && event.keyCode == 9 {
                Task { @MainActor in
                    self?.togglePopover()
                }
                return nil
            }
            return event
        }

        cancellable = SystemMonitor.shared.$snapshot.map { _ in () }
            .merge(with: UserPreferences.shared.$menuBarDisplayMode.map { _ in () })
            .merge(with: UserPreferences.shared.$temperatureUnit.map { _ in () })
            .sink { [weak self] _ in self?.updateMenuBarDisplay() }
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
            SystemMonitor.shared.isPopoverVisible = false
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            SystemMonitor.shared.isPopoverVisible = true
        }
    }

    private func updateMenuBarDisplay() {
        guard let button = statusItem?.button else { return }
        let mode = UserPreferences.shared.menuBarDisplayMode

        switch mode {
        case .iconOnly:
            button.title = ""
            button.image = makeStatusBarIcon()
        case .iconAndCPU:
            if let snapshot = SystemMonitor.shared.snapshot {
                button.title = " " + Formatters.percentage(snapshot.cpu.totalUsage)
            }
            button.image = makeStatusBarIcon()
        case .iconAndTemp:
            if let snapshot = SystemMonitor.shared.snapshot,
               let temp = snapshot.thermal.cpuTemperature {
                button.title = " " + Formatters.temperature(temp, unit: UserPreferences.shared.temperatureUnit)
            } else {
                button.title = " --"
            }
            button.image = makeStatusBarIcon()
        case .cpuGraph:
            button.title = ""
            if let snapshot = SystemMonitor.shared.snapshot, !snapshot.cpu.coreUsages.isEmpty {
                button.image = renderCPUBarGraph(coreUsages: snapshot.cpu.coreUsages)
            }
        case .memoryRing:
            button.title = ""
            if let snapshot = SystemMonitor.shared.snapshot {
                button.image = renderMemoryRing(usagePercent: snapshot.memory.usagePercentage)
            }
        }

        if mode == .iconAndCPU || mode == .iconAndTemp {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
    }

    private func renderCPUBarGraph(coreUsages: [Double]) -> NSImage {
        let width: CGFloat = 24
        let height: CGFloat = 18
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        let barCount = min(coreUsages.count, 12)
        let barWidth = max(width / CGFloat(barCount) - 1, 1)
        for (i, usage) in coreUsages.prefix(barCount).enumerated() {
            let x = CGFloat(i) * (barWidth + 1)
            let barHeight = max(CGFloat(usage / 100) * height, 1)
            let color: NSColor = usage > 90 ? .systemRed : usage > 70 ? .systemOrange : .systemGreen
            color.setFill()
            NSBezierPath(rect: NSRect(x: x, y: 0, width: barWidth, height: barHeight)).fill()
        }
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func renderMemoryRing(usagePercent: Double) -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        let lineWidth: CGFloat = 2.5
        let center = NSPoint(x: size / 2, y: size / 2)
        let radius = (size - lineWidth) / 2
        NSColor.systemGray.withAlphaComponent(0.3).setStroke()
        let bgPath = NSBezierPath()
        bgPath.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        bgPath.lineWidth = lineWidth
        bgPath.stroke()
        let color: NSColor = usagePercent > 90 ? .systemRed : usagePercent > 70 ? .systemOrange : .systemGreen
        color.setStroke()
        let fgPath = NSBezierPath()
        let startAngle: CGFloat = 90
        let endAngle = startAngle - CGFloat(usagePercent / 100 * 360)
        fgPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        fgPath.lineWidth = lineWidth
        fgPath.lineCapStyle = .round
        fgPath.stroke()
        image.unlockFocus()
        image.isTemplate = false
        return image
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
