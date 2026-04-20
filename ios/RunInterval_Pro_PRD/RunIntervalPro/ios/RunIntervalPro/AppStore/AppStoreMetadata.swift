import Foundation

// MARK: - App Store Metadata
// Source of truth for all ASO-related copy.
// Update these constants before each App Store submission.
//
// MARK: - App Name (30 chars max)
// Primary:  "RunInterval Pro: Running Timer" (28 chars)
// Alternative: "RunInterval - Running Timer" (30 chars)
enum ASOMetadata {
    // MARK: - App Name & Subtitle
    static let appName = "RunInterval Pro"
    static let subtitle = "Interval training for runners"

    // MARK: - Keywords (100 chars total, split by commas)
    // Primary Set
    static let primaryKeywords = [
        "interval", "timer", "running", "workout", "hiit",
        "tabata", "training", "run", "pace", "fartlek"
    ]
    // Alternative Set (test variations)
    static let alternativeKeywords = [
        "intervaltimer", "runworkout", "hittimer", "fitness",
        "coach", "track", "speed", "race", "splits"
    ]

    // MARK: - Short Description (170 chars)
    static let shortDescription =
        "The interval timer built specifically for runners. " +
        "Create custom workouts, follow presets, and train with your Apple Watch."

    // MARK: - Full Description (see fullDescriptionLong below, split for readability)
    static let fullDescriptionOpening =
        """
        Stop fumbling with complicated timer apps during your run. \
        RunInterval Pro is the interval timer designed specifically for runners \
        — from casual joggers to marathon trainers.
        """

    static let fullDescriptionBulletPoints = [
        "Start your workout in under 10 seconds with preset interval schemes",
        "HIIT, Tabata, Fartlek, Tempo runs, and more—ready to go",
        "Large, gesture-based controls that work with sweaty hands",
        "Full Apple Watch support for phone-free training"
    ]

    static let fullDescriptionFeatures = [
        ("CUSTOM WORKOUTS",
         "Build any interval structure you need: warm-up, work phases, rest periods, repeats. "
         + "Save your favorites and organize them into folders."),
        ("RUNNER-OPTIMIZED INTERFACE",
         "Big numbers you can read at a glance. Swipe to skip or repeat phases. "
         + "Tap anywhere to pause. Designed for motion, not standing still."),
        ("APPLE WATCH INTEGRATION",
         "Leave your phone at home. The Watch app delivers haptic feedback for "
         + "every phase change, with distinct vibration patterns you can feel while running."),
        ("SHARE WITH YOUR TEAM",
         "Coaches can create workouts and share via QR code. Athletes scan and go—no setup required.")
    ]

    static let fullDescriptionClosing =
        """
        Built by runners, for runners. Whether you're doing Yasso 800s, \
        pyramid intervals, or your own custom protocol, RunInterval Pro keeps you on pace.
        Download now and make every interval count.
        """

    // MARK: - Subscription Info (in description)
    static let subscriptionCopy =
        """
        RunInterval Pro offers a free version with 3 preset workouts. \
        Unlock unlimited custom workouts, Apple Watch support, and sharing features \
        with RunInterval Pro subscription.
        • Monthly: $2.99
        • Yearly: $19.99 (44% savings)
        """

    // MARK: - Screenshot Overlay Texts
    static let screenshot1 = "Interval Timer for Runners"
    static let screenshot2 = "10+ Preset Workouts"
    static let screenshot3 = "Build Custom Intervals"
    static let screenshot4 = "Train Phone-Free"
    static let screenshot5 = "Share with Your Team"
    static let screenshot6 = "Track Your Progress"

    // MARK: - Review Prompt
    static let reviewPromptTriggerCount = 5

    // MARK: - Localization Additions by Market
    static let ukKeywords = ["pace", "splits", "parkrun", "athletics"]
    static let australiaKeywords = ["footy training", "cricket nets", "beach runs"]
    static let canadaKeywords = ["track and field", "cross country"]
}
