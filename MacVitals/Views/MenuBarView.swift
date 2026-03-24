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

                tabContent
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
            .focusable(false)

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
            .focusable(false)
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
        .padding(.top, 6)
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
            .padding(.top, 4)
            .padding(.bottom, 6)
            .foregroundStyle(preferences.selectedTab == index ? Theme.Colors.accentCyan : Theme.Colors.textTertiary)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(preferences.selectedTab == index ? Theme.Colors.accentCyan : .clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
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
