import SwiftUI

struct MenuBarView: View {
    @State private var viewModel = MenuBarViewModel()
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    OverviewSection(
                        snapshot: viewModel.snapshot,
                        cpuHistory: SystemMonitor.shared.cpuHistory,
                        memoryHistory: SystemMonitor.shared.memoryHistory
                    )

                    if preferences.showCPUSection {
                        CPUSectionView(cpu: viewModel.snapshot?.cpu ?? .empty)
                    }

                    if preferences.showMemorySection {
                        MemorySectionView(memory: viewModel.snapshot?.memory ?? .empty)
                    }

                    if preferences.showStorageSection {
                        StorageSectionView(storage: viewModel.snapshot?.storage ?? .empty)
                    }

                    if preferences.showBatterySection, let battery = viewModel.snapshot?.battery {
                        BatterySectionView(battery: battery)
                    }

                    if preferences.showNetworkSection {
                        NetworkSectionView(network: viewModel.snapshot?.network ?? .empty)
                    }

                    if let gpu = viewModel.snapshot?.gpu {
                        GPUSectionView(gpu: gpu)
                    }

                    if preferences.showThermalSection {
                        ThermalSectionView(thermal: viewModel.snapshot?.thermal ?? .empty)
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
