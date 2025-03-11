import SwiftUI
import AppKit

@available(macOS 11.0, *)
struct TimerControlButton: View {
    // Keep a direct reference to the timer
    @ObservedObject var timer: PomodoroTimer
    
    // Local state to track observed changes and force refresh
    @State private var forceRefresh = false
    
    var body: some View {
        Button {
            // Toggle the timer state
            if timer.isRunning {
                timer.pause()
            } else {
                timer.start()
            }
            
            // Also toggle our local state to force a refresh
            forceRefresh.toggle()
        } label: {
            // Use the CURRENT state of the timer, not binding
            Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                .foregroundColor(.white)
        }
        .buttonStyle(.bordered)
        // Force view to redraw when our refresh state changes
        .id("playButton-\(timer.isRunning)-\(forceRefresh)")
    }
}

@available(macOS 11.0, *)
struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pomodorian")
                    .font(.headline)
                
                Spacer()
                
                // Play/Pause button with custom refreshing state
                TimerControlButton(timer: appState.pomodoroTimer)
                
                Button {
                    // Show a native macOS alert instead
                    let alert = NSAlert()
                    alert.messageText = "Reset Timer?"
                    alert.informativeText = "Are you sure you want to reset the timer?"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Reset")
                    alert.addButton(withTitle: "Cancel")
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        appState.pomodoroTimer.reset()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Display Options
            Group {
                Toggle("Show Minutes", isOn: $appState.showMinutes)
                Toggle("Show Seconds", isOn: $appState.showSeconds)
                Toggle("Use Pie Chart", isOn: $appState.usePieChart)
            }
            
            Divider()
            
            // Timer Settings
            Group {
                Text("Timer Duration")
                    .font(.headline)
                    .padding(.top, 4)
                
                HStack {
                    Stepper(value: $appState.customTimerMinutes, in: 1...60) {
                        HStack {
                            Text("Minutes:")
                            Text("\(appState.customTimerMinutes)")
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
                
                HStack {
                    Stepper(value: $appState.customTimerSeconds, in: 0...59) {
                        HStack {
                            Text("Seconds:")
                            Text("\(appState.customTimerSeconds)")
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
            
            Divider()
            
            // Color Settings
            Group {
                Text("Color Settings")
                    .font(.headline)
                    .padding(.top, 4)
                    
                ColorPicker("Empty Color", selection: $appState.emptyColor)
                ColorPicker("Full Color", selection: $appState.fullColor)
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Quit") {
                    let alert = NSAlert()
                    alert.messageText = "Quit Pomodorian?"
                    alert.informativeText = "Are you sure you want to quit the application?"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Quit")
                    alert.addButton(withTitle: "Cancel")
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(width: 300)
        // Add refresh listener to ensure we get timer state changes
        .onReceive(NotificationCenter.default.publisher(for: .timerStateChanged)) { _ in
            // This will be called when the timer state changes
        }
    }
}