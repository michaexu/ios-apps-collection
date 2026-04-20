import SwiftUI

struct WorkoutLibraryView: View {
    @StateObject private var viewModel = WorkoutLibraryViewModel()
    @State private var selectedWorkout: Workout?
    @State private var showingEditor = false
    @State private var editingWorkout: Workout?
    @State private var showingQRScanner = false
    @State private var showingShareSheet = false
    @State private var shareWorkout: Workout?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Folder tabs
                folderTabs

                // Workout list
                if viewModel.filteredWorkouts.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .navigationTitle("Library")
            .searchable(text: $viewModel.searchText, prompt: "Search workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            editingWorkout = nil
                            showingEditor = true
                        } label: {
                            Label("New Workout", systemImage: "plus")
                        }

                        Button {
                            showingQRScanner = true
                        } label: {
                            Label("Import from QR", systemImage: "qrcode.viewfinder")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                WorkoutEditorView(workout: editingWorkout) { saved in
                    viewModel.loadWorkouts()
                }
            }
            .sheet(item: $shareWorkout) { workout in
                ShareWorkoutSheet(workout: workout)
            }
        }
    }

    private var folderTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", selected: viewModel.selectedFolder == nil) {
                    viewModel.selectedFolder = nil
                }

                ForEach(viewModel.folders, id: \.self) { folder in
                    FilterChip(title: folder, selected: viewModel.selectedFolder == folder) {
                        viewModel.selectedFolder = folder
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private var workoutList: some View {
        List {
            ForEach(viewModel.filteredWorkouts) { workout in
                WorkoutRow(workout: workout)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedWorkout = workout
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteWorkout(workout)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            editingWorkout = workout
                            showingEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            shareWorkout = workout
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)

                        Button {
                            viewModel.duplicateWorkout(workout)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.green)
                    }
            }
        }
        .listStyle(.plain)
        .sheet(item: $selectedWorkout) { workout in
            ActiveWorkoutView(workout: workout)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Workouts Yet")
                .font(.title2.bold())

            Text("Create your first custom workout\nor import one via QR code")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                editingWorkout = nil
                showingEditor = true
            } label: {
                Label("Create Workout", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "FF6B35"))

            Spacer()
        }
        .padding()
    }
}

// MARK: - FilterChip
struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selected ? Color(hex: "FF6B35") : Color(.secondarySystemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - WorkoutRow
struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            // Phase dots
            VStack(spacing: 3) {
                ForEach(workout.cycles.first?.phases.prefix(4) ?? [], id: \.id) { phase in
                    Circle()
                        .fill(phase.type.color)
                        .frame(width: 7, height: 7)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(workout.totalDurationFormatted, systemImage: "clock")
                    Label("\(workout.phaseCount) phases", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !workout.workoutDescription.isEmpty {
                    Text(workout.workoutDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "FF6B35"))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkoutLibraryView()
}
