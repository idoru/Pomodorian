import Foundation
import SwiftUI

class PomodoroTimer: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var timeRemaining: TimeInterval = 25 * 60 // 25 minutes in seconds
    
    private var totalTime: TimeInterval = 25 * 60 // 25 minutes in seconds
    private var timer: Timer?
    
    func start() {
        if !isRunning {
            isRunning = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1.0
                    self.progress = 1.0 - (self.timeRemaining / self.totalTime)
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
    @Published var showMinutes: Bool = true
    @Published var showSeconds: Bool = true
    @Published var usePieChart: Bool = false
    @Published var emptyColor: Color = Color.pink.opacity(0.3)
    @Published var fullColor: Color = Color.red
    @Published var customTimerMinutes: Int = 25
    @Published var customTimerSeconds: Int = 0
    
    func resetTimerWithCustomDuration() {
        pomodoroTimer.reset(withDuration: TimeInterval(customTimerMinutes * 60 + customTimerSeconds))
    }
}