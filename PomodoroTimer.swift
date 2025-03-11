import Foundation
import SwiftUI

class PomodoroTimer: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var timeRemaining: TimeInterval = 25 * 60 // 25 minutes in seconds
    
    private var totalTime: TimeInterval = 25 * 60 // 25 minutes in seconds
    private var startTime: Date?
    private var pausedTimeRemaining: TimeInterval = 25 * 60
    private var timer: Timer?
    
    // Start the timer with direct mechanism
    func start() {
        if isRunning { return }
        
        // Get updated duration settings from AppState when starting from reset state
        if let appState = (NSApplication.shared.delegate as? AppDelegate)?.appState, 
           pausedTimeRemaining == totalTime && timeRemaining == totalTime {
            let newDuration = TimeInterval(appState.customTimerMinutes * 60 + appState.customTimerSeconds)
            if newDuration != totalTime {
                reset(withDuration: newDuration)
            }
        }
        
        isRunning = true
        startTime = Date()
        
        // When starting from paused state, calculate adjusted start time
        if pausedTimeRemaining < totalTime {
            let elapsedTime = totalTime - pausedTimeRemaining
            startTime = Date().addingTimeInterval(-elapsedTime)
        }
        
        // Create a repeating timer that updates every 0.1 seconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        timer?.tolerance = 0.02
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
        reset(withDuration: totalTime)
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
    @Published var pomodoroTimer = PomodoroTimer()
    
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
        
        showMinutes = defaults.object(forKey: kShowMinutes) as? Bool ?? true
        showSeconds = defaults.object(forKey: kShowSeconds) as? Bool ?? true
        usePieChart = defaults.object(forKey: kUsePieChart) as? Bool ?? false
        
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
        
        customTimerMinutes = defaults.object(forKey: kCustomTimerMinutes) as? Int ?? 25
        customTimerSeconds = defaults.object(forKey: kCustomTimerSeconds) as? Int ?? 0
    }
    
    // Save all settings to UserDefaults
    private func saveSettings() {
        let defaults = UserDefaults.standard
        
        // Save boolean settings
        defaults.set(showMinutes, forKey: kShowMinutes)
        defaults.set(showSeconds, forKey: kShowSeconds)
        defaults.set(usePieChart, forKey: kUsePieChart)
        
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
}