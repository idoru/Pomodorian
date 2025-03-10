import Foundation
import SwiftUI

class PomodoroTimer: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var timeRemaining: TimeInterval = 25 * 60 // 25 minutes in seconds
    @Published var lastUpdate: Date = Date() // To force UI updates
    
    private var totalTime: TimeInterval = 25 * 60 // 25 minutes in seconds
    private var timer: Timer?
    
    func start() {
        if !isRunning {
            isRunning = true
            lastUpdate = Date()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1.0
                    self.progress = 1.0 - (self.timeRemaining / self.totalTime)
                    self.lastUpdate = Date() // Force update the UI
                } else {
                    self.complete()
                }
            }
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        reset(withDuration: totalTime)
    }
    
    func reset(withDuration duration: TimeInterval) {
        pause()
        totalTime = duration
        timeRemaining = duration
        progress = 0.0
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
            // Force UI update when toggling display options
            NotificationCenter.default.post(name: NSNotification.Name("RefreshStatusBar"), object: nil)
        }
    }
    @Published var showSeconds: Bool = true {
        didSet {
            // Force UI update when toggling display options
            NotificationCenter.default.post(name: NSNotification.Name("RefreshStatusBar"), object: nil)
        }
    }
    @Published var usePieChart: Bool = false {
        didSet {
            // Force UI update when toggling display options
            NotificationCenter.default.post(name: NSNotification.Name("RefreshStatusBar"), object: nil)
        }
    }
    @Published var emptyColor: Color = Color.pink.opacity(0.3)
    @Published var fullColor: Color = Color.red
    @Published var customTimerMinutes: Int = 25
    @Published var customTimerSeconds: Int = 0
    
    func resetTimerWithCustomDuration() {
        pomodoroTimer.reset(withDuration: TimeInterval(customTimerMinutes * 60 + customTimerSeconds))
    }
}