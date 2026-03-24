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

                if preferences.showCPUSection {
                    CPUSectionView(cpu: monitor.snapshot?.cpu ?? .empty)
                        .cardStyle()
                }

                if preferences.showMemorySection {
                    MemorySectionView(memory: monitor.snapshot?.memory ?? .empty)
                        .cardStyle()
                }

                if preferences.showStorageSection {
                    StorageSectionView(storage: monitor.snapshot?.storage ?? .empty)
                        .cardStyle()
                }

                if preferences.showBatterySection, let battery = monitor.snapshot?.battery {
                    BatterySectionView(battery: battery)
                        .cardStyle()
                }

                if preferences.showNetworkSection {
                    NetworkSectionView(network: monitor.snapshot?.network ?? .empty)
                        .cardStyle()
                }

                if let gpu = monitor.snapshot?.gpu {
                    GPUSectionView(gpu: gpu)
                        .cardStyle()
                }

                if preferences.showThermalSection {
                    ThermalSectionView(thermal: monitor.snapshot?.thermal ?? .empty)
                        .cardStyle()
                }

                if let btDevices = monitor.snapshot?.bluetooth, !btDevices.isEmpty {
                    BluetoothSectionView(devices: btDevices)
                        .cardStyle()
                }
            }
            .padding(Theme.Spacing.contentPadding)
        }
    }
}
