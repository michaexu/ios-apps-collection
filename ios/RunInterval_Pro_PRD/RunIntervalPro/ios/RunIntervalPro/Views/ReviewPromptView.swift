import SwiftUI
import StoreKit

// MARK: - ReviewPromptView
/// ASO PRD §6.1: Triggered after user's 5th completed workout.
/// One prompt per version update (tracked via UserDefaults).
struct ReviewPromptView: View {
    @Binding var isPresented: Bool
    let workoutName: String

    private let reviewCopy = "Enjoying RunInterval Pro? Tap to rate the app and help other runners find it. What do you use RunInterval for? (e.g., HIIT workouts, marathon training, Yasso 800s)"

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "star.bubble.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "FF6B35"))

            VStack(spacing: 8) {
                Text("Enjoying RunInterval Pro?")
                    .font(.headline)

                Text("What do you use it for? (e.g., HIIT workouts, marathon training, Yasso 800s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    requestReview()
                } label: {
                    Text("Rate on App Store")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "FF6B35"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Not now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 32)
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        dismiss()
    }

    private func dismiss() {
        isPresented = false
        // Mark as prompted for this version
        UserDefaults.standard.set(AppConfig.currentVersion, forKey: "reviewed_version")
    }
}

// MARK: - ReviewPromptManager
/// Call `ReviewPromptManager.maybePrompt()` after a workout finishes.
enum ReviewPromptManager {
    private static let key_reviewedVersion = "reviewed_version"

    static var shouldPrompt: Bool {
        let completed = StorageService.shared.loadSummaries().count
        let lastVersion = UserDefaults.standard.string(forKey: key_reviewedVersion)
        return completed >= 5 && completed % 5 == 0 && lastVersion != AppConfig.currentVersion
    }

    static func markPrompted() {
        UserDefaults.standard.set(AppConfig.currentVersion, forKey: key_reviewedVersion)
    }
}

// MARK: - AppConfig
enum AppConfig {
    static let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}
