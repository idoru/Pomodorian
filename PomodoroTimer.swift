import Foundation
import SwiftUI
import ServiceManagement

class PomodoroTimer: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var timeRemaining: TimeInterval

    private var totalTime: TimeInterval
    private var startTime: Date?
    private var pausedTimeRemaining: TimeInterval

    init(duration: TimeInterval = 25 * 60) {
        self.totalTime = duration
        self.timeRemaining = duration
        self.pausedTimeRemaining = duration
    }

    private var timer: Timer?

    // Start the timer with direct mechanism
    func start() {
        if isRunning { return }

        // If timer has already expired, reset it first
        if timeRemaining <= 0 {
            reset()
        }

        isRunning = true
        startTime = Date()

        // When starting from paused state, calculate adjusted start time
        if pausedTimeRemaining < totalTime {
            let elapsedTime = totalTime - pausedTimeRemaining
            startTime = Date().addingTimeInterval(-elapsedTime)
        }

        // Create a repeating timer that updates every 0.5 seconds for better performance
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        timer?.tolerance = 0.1
        RunLoop.main.add(timer!, forMode: .common)

        // Initial update
        updateTimer()
        objectWillChange.send()

        // Post notification to update UI
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
    }

    // Update timer state
    private func updateTimer() {
        guard let startTime = startTime, isRunning else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        timeRemaining = max(0, totalTime - elapsed)
        progress = min(1.0, elapsed / totalTime)

        if timeRemaining <= 0 {
            complete()
        }

        objectWillChange.send()
    }

    // Pause the timer
    func pause() {
        guard isRunning else { return }

        pausedTimeRemaining = timeRemaining
        isRunning = false
        timer?.invalidate()
        timer = nil
        objectWillChange.send()

        // Post notification to update UI
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
    }

    func reset() {
        // Check for updated duration settings from AppState
        if let appState = (NSApplication.shared.delegate as? AppDelegate)?.appState {
            let newDuration = TimeInterval(appState.customTimerMinutes * 60 + appState.customTimerSeconds)
            reset(withDuration: newDuration)
        } else {
            reset(withDuration: totalTime)
        }
    }

    func reset(withDuration duration: TimeInterval) {
        pause()
        totalTime = duration
        timeRemaining = duration
        pausedTimeRemaining = duration
        progress = 0.0
        startTime = nil

        // Force UI update
        objectWillChange.send()
    }

    private func complete() {
        pause()
        // Simply play a system sound when timer completes
        NSSound.beep()

        // Display a simple alert if possible
        if let app = NSApplication.shared.delegate as? AppDelegate {
            app.showAlert(title: "Pomodoro Timer", message: "Time's up! Take a break.")
        }
    }

    deinit {
        timer?.invalidate()
    }
}

class AppState: ObservableObject {
    @Published var pomodoroTimer: PomodoroTimer

    @Published var showMinutes: Bool {
        didSet {
            NotificationCenter.default.post(name: .timerStateChanged, object: nil)
            saveSettings()
        }
    }

    @Published var showSeconds: Bool {
        didSet {
            NotificationCenter.default.post(name: .timerStateChanged, object: nil)
            saveSettings()
        }
    }

    @Published var usePieChart: Bool {
        didSet {
            NotificationCenter.default.post(name: .timerStateChanged, object: nil)
            saveSettings()
        }
    }

    @Published var startAtLogin: Bool {
        didSet {
            updateLoginItemStatus()
            saveSettings()
        }
    }

    @Published var emptyColor: Color {
        didSet {
            NotificationCenter.default.post(name: .colorSettingsChanged, object: nil)
            saveSettings()
        }
    }

    @Published var fullColor: Color {
        didSet {
            NotificationCenter.default.post(name: .colorSettingsChanged, object: nil)
            saveSettings()
        }
    }

    @Published var customTimerMinutes: Int {
        didSet {
            saveSettings()
        }
    }

    @Published var customTimerSeconds: Int {
        didSet {
            saveSettings()
        }
    }

    // Keys for UserDefaults
    private let kShowMinutes = "showMinutes"
    private let kShowSeconds = "showSeconds"
    private let kUsePieChart = "usePieChart"
    private let kStartAtLogin = "startAtLogin"
    private let kEmptyColorRed = "emptyColorRed"
    private let kEmptyColorGreen = "emptyColorGreen"
    private let kEmptyColorBlue = "emptyColorBlue"
    private let kEmptyColorOpacity = "emptyColorOpacity"
    private let kFullColorRed = "fullColorRed"
    private let kFullColorGreen = "fullColorGreen"
    private let kFullColorBlue = "fullColorBlue"
    private let kFullColorOpacity = "fullColorOpacity"
    private let kCustomTimerMinutes = "customTimerMinutes"
    private let kCustomTimerSeconds = "customTimerSeconds"

    init() {
        // Load saved settings or use defaults
        let defaults = UserDefaults.standard

        // Extract timer settings first
        let minutes = defaults.object(forKey: kCustomTimerMinutes) as? Int ?? 25
        let seconds = defaults.object(forKey: kCustomTimerSeconds) as? Int ?? 0
        let initialDuration = TimeInterval(minutes * 60 + seconds)

        // Initialize the timer first
        pomodoroTimer = PomodoroTimer(duration: initialDuration)

        // Now initialize the rest of properties
        customTimerMinutes = minutes
        customTimerSeconds = seconds
        showMinutes = defaults.object(forKey: kShowMinutes) as? Bool ?? true
        showSeconds = defaults.object(forKey: kShowSeconds) as? Bool ?? true
        usePieChart = defaults.object(forKey: kUsePieChart) as? Bool ?? false
        startAtLogin = defaults.object(forKey: kStartAtLogin) as? Bool ?? false

        // Load colors
        if let emptyRed = defaults.object(forKey: kEmptyColorRed) as? Double,
           let emptyGreen = defaults.object(forKey: kEmptyColorGreen) as? Double,
           let emptyBlue = defaults.object(forKey: kEmptyColorBlue) as? Double,
           let emptyOpacity = defaults.object(forKey: kEmptyColorOpacity) as? Double {
            emptyColor = Color(.sRGB, red: emptyRed, green: emptyGreen, blue: emptyBlue, opacity: emptyOpacity)
        } else {
            emptyColor = Color.pink.opacity(0.3)
        }

        if let fullRed = defaults.object(forKey: kFullColorRed) as? Double,
           let fullGreen = defaults.object(forKey: kFullColorGreen) as? Double,
           let fullBlue = defaults.object(forKey: kFullColorBlue) as? Double,
           let fullOpacity = defaults.object(forKey: kFullColorOpacity) as? Double {
            fullColor = Color(.sRGB, red: fullRed, green: fullGreen, blue: fullBlue, opacity: fullOpacity)
        } else {
            fullColor = Color.red
        }
    }

    // Save all settings to UserDefaults
    private func saveSettings() {
        let defaults = UserDefaults.standard

        // Save boolean settings
        defaults.set(showMinutes, forKey: kShowMinutes)
        defaults.set(showSeconds, forKey: kShowSeconds)
        defaults.set(usePieChart, forKey: kUsePieChart)
        defaults.set(startAtLogin, forKey: kStartAtLogin)

        // Save colors - first convert to RGB components
        let nsEmptyColor = NSColor(emptyColor)
        if let rgbEmpty = nsEmptyColor.usingColorSpace(.sRGB) {
            defaults.set(rgbEmpty.redComponent, forKey: kEmptyColorRed)
            defaults.set(rgbEmpty.greenComponent, forKey: kEmptyColorGreen)
            defaults.set(rgbEmpty.blueComponent, forKey: kEmptyColorBlue)
            defaults.set(rgbEmpty.alphaComponent, forKey: kEmptyColorOpacity)
        }

        let nsFullColor = NSColor(fullColor)
        if let rgbFull = nsFullColor.usingColorSpace(.sRGB) {
            defaults.set(rgbFull.redComponent, forKey: kFullColorRed)
            defaults.set(rgbFull.greenComponent, forKey: kFullColorGreen)
            defaults.set(rgbFull.blueComponent, forKey: kFullColorBlue)
            defaults.set(rgbFull.alphaComponent, forKey: kFullColorOpacity)
        }

        // Save timer settings
        defaults.set(customTimerMinutes, forKey: kCustomTimerMinutes)
        defaults.set(customTimerSeconds, forKey: kCustomTimerSeconds)
    }

    // This function is kept for backward compatibility
    // but the timer now automatically applies custom duration when started
    func resetTimerWithCustomDuration() {
        pomodoroTimer.reset(withDuration: TimeInterval(customTimerMinutes * 60 + customTimerSeconds))
    }

    // Update login item status based on user preference
    private func updateLoginItemStatus() {
        if #available(macOS 13.0, *) {
            // Use the newer SMAppService API for macOS 13+
            let service = SMAppService.mainApp

            do {
                if startAtLogin {
                    if service.status == .notRegistered {
                        try service.register()
                    }
                } else {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                }
            } catch {
                print("Failed to \(startAtLogin ? "register" : "unregister") login item: \(error.localizedDescription)")
            }
        } else {
            // Use the older SMLoginItemSetEnabled API for earlier macOS versions
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.pomodorian"
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, startAtLogin)

            if !success {
                print("Failed to \(startAtLogin ? "register" : "unregister") login item using legacy API")
            }
        }
    }
}