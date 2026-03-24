import SwiftUI
import AppKit

enum ExportDuration: Int, CaseIterable, Identifiable {
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case oneHour = 60

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fiveMinutes: return "Last 5 min"
        case .fifteenMinutes: return "Last 15 min"
        case .oneHour: return "Last 1 hour"
        }
    }
}

struct ExportView: View {
    @State private var selectedDuration: ExportDuration = .fifteenMinutes
    @State private var exportStatus: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Export Performance Data")
                .font(.headline)

            Text("\(DataRecorder.shared.snapshotCount) snapshots recorded")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Duration", selection: $selectedDuration) {
                ForEach(ExportDuration.allCases) { duration in
                    Text(duration.displayName).tag(duration)
                }
            }
            .pickerStyle(.segmented)

            if let status = exportStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(status.contains("Error") ? .red : .green)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Export CSV") { exportCSV() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func exportCSV() {
        guard let fileURL = DataRecorder.shared.exportCSV(lastMinutes: selectedDuration.rawValue) else {
            exportStatus = "Error: no data for selected period"
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = fileURL.lastPathComponent
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let dest = panel.url {
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: fileURL, to: dest)
                exportStatus = "Exported successfully"
            } catch {
                exportStatus = "Error: \(error.localizedDescription)"
            }
        }
    }
}
