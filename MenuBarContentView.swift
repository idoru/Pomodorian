import SwiftUI
import AppKit

@available(macOS 11.0, *)
struct TimerControlButton: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            // Toggle the timer state
            if appState.pomodoroTimer.isRunning {
                appState.pomodoroTimer.pause()
            } else {
                appState.pomodoroTimer.start()
            }
        } label: {
            // Use the CURRENT state of the timer through environment
            Image(systemName: appState.pomodoroTimer.isRunning ? "pause.fill" : "play.fill")
                .foregroundColor(.white)
        }
        .buttonStyle(.bordered)
    }
}

@available(macOS 11.0, *)
struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var timerStateObserver: NSObjectProtocol?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pomodorian")
                    .font(.headline)

                Spacer()

                // Play/Pause button
                TimerControlButton()

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
                Toggle("Start at Login", isOn: $appState.startAtLogin)
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
        .onAppear {
            // Set up observer when view appears
            timerStateObserver = NotificationCenter.default.addObserver(
                forName: .timerStateChanged,
                object: nil,
                queue: .main
            ) { _ in
                // This will be called when the timer state changes
                // The @Published properties will automatically trigger UI updates
            }
        }
        .onDisappear {
            // Clean up observer when view disappears
            if let observer = timerStateObserver {
                NotificationCenter.default.removeObserver(observer)
                timerStateObserver = nil
            }
        }
    }
}