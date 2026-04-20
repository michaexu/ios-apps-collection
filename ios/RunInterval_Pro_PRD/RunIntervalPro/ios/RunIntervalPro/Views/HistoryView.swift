import SwiftUI

struct HistoryView: View {
    @State private var summaries: [WorkoutSummary] = []

    var groupedSummaries: [(date: Date, items: [WorkoutSummary])] {
        let grouped = Dictionary(grouping: summaries) { summary in
            Calendar.current.startOfDay(for: summary.completedAt)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, items: $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if summaries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedSummaries, id: \.date) { group in
                            Section {
                                ForEach(group.items) { summary in
                                    HistoryRow(summary: summary)
                                }
                            } header: {
                                Text(formatDate(group.date))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .onAppear { loadSummaries() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No History Yet")
                .font(.title2.bold())
            Text("Complete your first workout\nto see it here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private func loadSummaries() {
        summaries = StorageService.shared.loadSummaries()
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            fmt.dateStyle = .medium
            return fmt.string(from: date)
        }
    }
}

// MARK: - HistoryRow
struct HistoryRow: View {
    let summary: WorkoutSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.workoutName)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label(formatDuration(summary.totalDurationSeconds), systemImage: "clock")
                    Label("\(summary.phasesCompleted) phases", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)

                Text(formatTime(summary.completedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

#Preview {
    HistoryView()
}
