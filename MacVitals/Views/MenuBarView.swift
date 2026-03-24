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
                tabBar
                Divider()
                    .overlay(Theme.Colors.cardBorder)

                tabContent

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

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "Dashboard", icon: "gauge", index: 0)
            tabButton(title: "Processes", icon: "list.bullet", index: 1)
            tabButton(title: "Sensors", icon: "thermometer.medium", index: 2)
        }
        .padding(.horizontal, Theme.Spacing.contentPadding)
        .padding(.vertical, 6)
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            preferences.selectedTab = index
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(Theme.Fonts.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .foregroundStyle(preferences.selectedTab == index ? Theme.Colors.accentCyan : Theme.Colors.textTertiary)
            .overlay(alignment: .bottom) {
                if preferences.selectedTab == index {
                    Rectangle()
                        .fill(Theme.Colors.accentCyan)
                        .frame(height: 2)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch preferences.selectedTab {
        case 0:
            DashboardTabView()
        case 1:
            ProcessesTabView()
        case 2:
            SensorsTabView()
        default:
            DashboardTabView()
        }
    }
}
