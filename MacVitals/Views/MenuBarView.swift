import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                Divider()
                    .overlay(Theme.Colors.cardBorder)
                ScrollView {
                    VStack(spacing: Theme.Spacing.sectionSpacing) {
                        OverviewSection(
                            snapshot: monitor.snapshot,
                            cpuHistory: monitor.cpuHistory,
                            memoryHistory: monitor.memoryHistory
                        )
                        .cardStyle()

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
                    }
                    .padding(Theme.Spacing.contentPadding)
                }

                GradientBar()
                    .padding(.horizontal, Theme.Spacing.contentPadding)
                    .padding(.bottom, 8)
            }
        }
        .frame(
            width: Constants.popoverWidth,
            height: Constants.popoverHeight
        )
        .preferredColorScheme(.dark)
    }

    private var headerView: some View {
        HStack {
            Button(action: { WindowManager.shared.openSettingsWindow() }) {
                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(Constants.appName)
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            Button(action: { Constants.openGitHub() }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.contentPadding)
        .padding(.vertical, 12)
    }

}
