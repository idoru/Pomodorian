import SwiftUI

// Note: This view is no longer used directly in the status bar.
// We are now using native AppKit controls for more reliable updates.
@available(macOS 11.0, *)
struct StatusBarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 4) {
            if appState.usePieChart {
                PieProgressView(progress: appState.pomodoroTimer.progress)
                    .frame(width: 16, height: 16)
            } else {
                BarProgressView(progress: appState.pomodoroTimer.progress)
                    .frame(width: 8, height: 16)
            }
            
            if appState.showMinutes || appState.showSeconds {
                Text(timeString())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .fixedSize()
                    .frame(minWidth: 40, alignment: .leading)
            }
        }
        .frame(height: 22)
    }
    
    private func timeString() -> String {
        let time = appState.pomodoroTimer.timeRemaining
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let totalSeconds = Int(time)
        
        if appState.showMinutes && appState.showSeconds {
            return String(format: "%02d:%02d", minutes, seconds)
        } else if appState.showMinutes {
            return String(format: "%dm", minutes)
        } else if appState.showSeconds {
            // When only seconds are shown, display the total time in seconds
            return String(format: "%ds", totalSeconds)
        } else {
            return ""
        }
    }
}

@available(macOS 11.0, *)
// Note: These views are no longer used directly. 
// We are now using native AppKit controls for more reliable updates.

struct BarProgressView: View {
    @EnvironmentObject var appState: AppState
    var progress: Double
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            RoundedRectangle(cornerRadius: 2)
                .fill(appState.emptyColor)
                .frame(width: 8, height: 16)
            
            // Progress bar
            RoundedRectangle(cornerRadius: 2)
                .fill(appState.fullColor)
                .frame(width: 8, height: max(1, 16 * progress)) // Ensure at least 1 pixel high for visibility
        }
    }
}

@available(macOS 11.0, *)
struct PieProgressView: View {
    @EnvironmentObject var appState: AppState
    var progress: Double
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(appState.emptyColor)
            
            // Progress pie
            Circle()
                .trim(from: 0, to: CGFloat(max(0.001, progress))) // Ensure visibility with minimum value
                .rotation(.degrees(-90))
                .fill(appState.fullColor)
        }
    }
}