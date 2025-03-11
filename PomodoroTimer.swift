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
    
    @Published var showMinutes: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .timerStateChanged, object: nil)
        }
    }
    
    @Published var showSeconds: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .timerStateChanged, object: nil)
        }
    }
    
    @Published var usePieChart: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .timerStateChanged, object: nil)
        }
    }
    
    @Published var emptyColor: Color = Color.pink.opacity(0.3) {
        didSet {
            NotificationCenter.default.post(name: .colorSettingsChanged, object: nil)
        }
    }
    
    @Published var fullColor: Color = Color.red {
        didSet {
            NotificationCenter.default.post(name: .colorSettingsChanged, object: nil)
        }
    }
    
    @Published var customTimerMinutes: Int = 25
    @Published var customTimerSeconds: Int = 0
    
    func resetTimerWithCustomDuration() {
        pomodoroTimer.reset(withDuration: TimeInterval(customTimerMinutes * 60 + customTimerSeconds))
    }
}