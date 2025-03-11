import SwiftUI

@available(macOS 11.0, *)
struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTimerSettingsExpanded = false
    @State private var isColorSettingsExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pomodorian")
                    .font(.headline)
                
                Spacer()
                
                // Play/Pause button
                Button {
                    if appState.pomodoroTimer.isRunning {
                        appState.pomodoroTimer.pause()
                    } else {
                        appState.pomodoroTimer.start()
                    }
                } label: {
                    Image(systemName: appState.pomodoroTimer.isRunning ? "pause.fill" : "play.fill")
                        .foregroundColor(appState.pomodoroTimer.isRunning ? .red : .green)
                }
                .buttonStyle(.bordered)
                // Force button to update with a unique ID each time
                .id("playButton-\(appState.pomodoroTimer.isRunning)")
                
                Button {
                    appState.pomodoroTimer.reset()
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
            DisclosureGroup("Timer Duration", isExpanded: $isTimerSettingsExpanded) {
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
                
                Button("Apply Duration") {
                    appState.resetTimerWithCustomDuration()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
            }
            
            Divider()
            
            // Color Settings
            DisclosureGroup("Color Settings", isExpanded: $isColorSettingsExpanded) {
                ColorPicker("Empty Color", selection: $appState.emptyColor)
                ColorPicker("Full Color", selection: $appState.fullColor)
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(width: 300)
    }
}