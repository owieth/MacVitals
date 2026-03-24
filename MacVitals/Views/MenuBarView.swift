import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    OverviewSection(
                        snapshot: monitor.snapshot,
                        cpuHistory: monitor.cpuHistory,
                        memoryHistory: monitor.memoryHistory
                    )

                    if preferences.showCPUSection {
                        CPUSectionView(cpu: monitor.snapshot?.cpu ?? .empty)
                    }

                    if preferences.showMemorySection {
                        MemorySectionView(memory: monitor.snapshot?.memory ?? .empty)
                    }

                    if preferences.showStorageSection {
                        StorageSectionView(storage: monitor.snapshot?.storage ?? .empty)
                    }

                    if preferences.showBatterySection, let battery = monitor.snapshot?.battery {
                        BatterySectionView(battery: battery)
                    }

                    if preferences.showNetworkSection {
                        NetworkSectionView(network: monitor.snapshot?.network ?? .empty)
                    }

                    if let gpu = monitor.snapshot?.gpu {
                        GPUSectionView(gpu: gpu)
                    }

                    if preferences.showThermalSection {
                        ThermalSectionView(thermal: monitor.snapshot?.thermal ?? .empty)
                    }
                }
                .padding(16)
            }
        }
        .frame(
            width: Constants.popoverWidth,
            height: Constants.popoverHeight
        )
    }

    private var headerView: some View {
        HStack {
            Button(action: { WindowManager.shared.openSettingsWindow() }) {
                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(Constants.appName)
                .font(.headline)

            Spacer()

            Button(action: { Constants.openGitHub() }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

}
