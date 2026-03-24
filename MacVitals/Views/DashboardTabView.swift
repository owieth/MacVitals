import SwiftUI

struct DashboardTabView: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.sectionSpacing) {
                OverviewSection(
                    snapshot: monitor.snapshot,
                    cpuHistory: monitor.cpuHistory,
                    memoryHistory: monitor.memoryHistory
                )
                .cardStyle()

                if !monitor.cpuHistory.isEmpty || !monitor.memoryHistory.isEmpty {
                    VStack(spacing: 8) {
                        if !monitor.cpuHistory.isEmpty {
                            HistoryChartView(
                                title: "CPU",
                                data: monitor.cpuHistory,
                                color: Theme.Colors.accentCyan,
                                maxValue: 100
                            )
                        }
                        if !monitor.memoryHistory.isEmpty {
                            HistoryChartView(
                                title: "Memory",
                                data: monitor.memoryHistory,
                                color: .green,
                                maxValue: 100
                            )
                        }
                        if !monitor.networkDownloadHistory.isEmpty {
                            HistoryChartView(
                                title: "Network ↓",
                                data: monitor.networkDownloadHistory,
                                color: .purple,
                                unit: "B/s"
                            )
                        }
                    }
                    .cardStyle()
                }

                ForEach(preferences.sectionOrder, id: \.self) { sectionID in
                    sectionView(for: sectionID)
                }
            }
            .padding(Theme.Spacing.contentPadding)
        }
    }

    @ViewBuilder
    private func sectionView(for id: String) -> some View {
        switch id {
        case "cpu":
            if preferences.showCPUSection {
                CPUSectionView(cpu: monitor.snapshot?.cpu ?? .empty)
                    .cardStyle()
                    .draggable(id) { dragPreview(id) }
                    .dropDestination(for: String.self) { items, _ in handleDrop(items, at: id) }
            }
        case "memory":
            if preferences.showMemorySection {
                MemorySectionView(memory: monitor.snapshot?.memory ?? .empty)
                    .cardStyle()
                    .draggable(id) { dragPreview(id) }
                    .dropDestination(for: String.self) { items, _ in handleDrop(items, at: id) }
            }
        case "storage":
            if preferences.showStorageSection {
                StorageSectionView(storage: monitor.snapshot?.storage ?? .empty)
                    .cardStyle()
                    .draggable(id) { dragPreview(id) }
                    .dropDestination(for: String.self) { items, _ in handleDrop(items, at: id) }
            }
        case "battery":
            if preferences.showBatterySection, let battery = monitor.snapshot?.battery {
                BatterySectionView(battery: battery)
                    .cardStyle()
                    .draggable(id) { dragPreview(id) }
                    .dropDestination(for: String.self) { items, _ in handleDrop(items, at: id) }
            }
        case "network":
            if preferences.showNetworkSection {
                NetworkSectionView(network: monitor.snapshot?.network ?? .empty)
                    .cardStyle()
                    .draggable(id) { dragPreview(id) }
                    .dropDestination(for: String.self) { items, _ in handleDrop(items, at: id) }
            }
        case "gpu":
            if let gpu = monitor.snapshot?.gpu {
                GPUSectionView(gpu: gpu)
                    .cardStyle()
                    .draggable(id) { dragPreview(id) }
                    .dropDestination(for: String.self) { items, _ in handleDrop(items, at: id) }
            }
        case "thermal":
            if preferences.showThermalSection {
                ThermalSectionView(thermal: monitor.snapshot?.thermal ?? .empty)
                    .cardStyle()
                    .draggable(id) { dragPreview(id) }
                    .dropDestination(for: String.self) { items, _ in handleDrop(items, at: id) }
            }
        case "bluetooth":
            if let btDevices = monitor.snapshot?.bluetooth, !btDevices.isEmpty {
                BluetoothSectionView(devices: btDevices)
                    .cardStyle()
                    .draggable(id) { dragPreview(id) }
                    .dropDestination(for: String.self) { items, _ in handleDrop(items, at: id) }
            }
        default:
            EmptyView()
        }
    }

    private func dragPreview(_ id: String) -> some View {
        Text(id.capitalized)
            .font(Theme.Fonts.sectionTitle)
            .foregroundStyle(Theme.Colors.accentCyan)
            .padding(8)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func handleDrop(_ items: [String], at target: String) -> Bool {
        guard let source = items.first,
              source != target,
              let sourceIndex = preferences.sectionOrder.firstIndex(of: source),
              let targetIndex = preferences.sectionOrder.firstIndex(of: target) else { return false }
        withAnimation(.easeInOut(duration: 0.2)) {
            preferences.sectionOrder.move(
                fromOffsets: IndexSet(integer: sourceIndex),
                toOffset: targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
            )
        }
        return true
    }
}
