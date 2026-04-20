import SwiftUI

struct ShareWorkoutSheet: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss

    @State private var qrImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Share '\(workout.name)'")
                    .font(.title2.bold())

                // QR Code
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .frame(width: 280, height: 280)

                    if let qrImage = qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 240, height: 240)
                    } else {
                        ProgressView()
                    }
                }
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                Text("Scan this QR code in RunInterval Pro to import this workout")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Workout summary
                VStack(spacing: 8) {
                    HStack {
                        Label(workout.totalDurationFormatted, systemImage: "clock")
                        Spacer()
                        Label("\(workout.phaseCount) phases", systemImage: "list.bullet")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if !workout.workoutDescription.isEmpty {
                        Text(workout.workoutDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            generateQR()
        }
    }

    private func generateQR() {
        qrImage = QRCodeService.shared.generateQRImage(from: workout, size: CGSize(width: 240, height: 240))
    }
}

#Preview {
    ShareWorkoutSheet(workout: PresetWorkout.classicHIIT.workout)
}
