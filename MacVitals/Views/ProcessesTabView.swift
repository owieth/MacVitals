import SwiftUI

enum ProcessSortMode: String, CaseIterable {
    case cpu = "CPU"
    case memory = "Memory"
}

struct ProcessesTabView: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @State private var sortMode: ProcessSortMode = .cpu
    @State private var searchText = ""
    @State private var allProcesses: [ProcessSnapshot] = []
    @State private var processCollector = ProcessCollector()
    @State private var confirmKillPID: Int32?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(Theme.Fonts.dataValue)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )

                Picker("Sort", selection: $sortMode) {
                    ForEach(ProcessSortMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            .padding(.horizontal, Theme.Spacing.contentPadding)
            .padding(.vertical, 8)

            processHeader

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(filteredProcesses) { process in
                        processRow(process)
                    }
                }
                .padding(.horizontal, Theme.Spacing.contentPadding)
            }
        }
        .onAppear { refreshProcesses() }
        .onReceive(monitor.$snapshot) { _ in refreshProcesses() }
        .alert("Force Quit", isPresented: showingAlert) {
            Button("Cancel", role: .cancel) { confirmKillPID = nil }
            Button("Force Quit", role: .destructive) {
                if let pid = confirmKillPID {
                    kill(pid, SIGTERM)
                    confirmKillPID = nil
                }
            }
        } message: {
            if let pid = confirmKillPID,
               let name = allProcesses.first(where: { $0.pid == pid })?.name {
                Text("Quit \"\(name)\" (PID \(pid))?")
            }
        }
    }

    private var showingAlert: Binding<Bool> {
        Binding(
            get: { confirmKillPID != nil },
            set: { if !$0 { confirmKillPID = nil } }
        )
    }

    private var processHeader: some View {
        HStack {
            Text("Process")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("CPU")
                .frame(width: 55, alignment: .trailing)
            Text("Memory")
                .frame(width: 65, alignment: .trailing)
            Spacer().frame(width: 28)
        }
        .font(Theme.Fonts.caption)
        .foregroundStyle(Theme.Colors.textTertiary)
        .padding(.horizontal, Theme.Spacing.contentPadding)
        .padding(.vertical, 4)
    }

    private var filteredProcesses: [ProcessSnapshot] {
        let sorted: [ProcessSnapshot]
        switch sortMode {
        case .cpu:
            sorted = allProcesses.sorted { $0.cpuUsage > $1.cpuUsage }
        case .memory:
            sorted = allProcesses.sorted { $0.memoryBytes > $1.memoryBytes }
        }

        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func processRow(_ process: ProcessSnapshot) -> some View {
        HStack {
            Text(process.name)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(Formatters.percentage(process.cpuUsage))
                .font(Theme.Fonts.caption.monospacedDigit())
                .foregroundStyle(process.cpuUsage > 50 ? Theme.Colors.warningOrange : Theme.Colors.textTertiary)
                .frame(width: 55, alignment: .trailing)

            Text(Formatters.bytes(process.memoryBytes))
                .font(Theme.Fonts.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(width: 65, alignment: .trailing)

            Button {
                confirmKillPID = process.pid
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
            .frame(width: 28)
            .accessibilityLabel("Force quit \(process.name)")
        }
        .padding(.vertical, 3)
    }

    private func refreshProcesses() {
        allProcesses = processCollector.collectAll()
    }
}
