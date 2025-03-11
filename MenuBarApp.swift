import Cocoa
import SwiftUI

// Notification names
extension Notification.Name {
    static let timerStateChanged = Notification.Name("timerStateChanged")
    static let colorSettingsChanged = Notification.Name("colorSettingsChanged")
}

@available(macOS 11.0, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var refreshTimer: Timer?
    var contentView: NSHostingController<MenuBarContentView>?
    var appState = AppState()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create popover for menu
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        
        // Set up the SwiftUI view for popover
        let contentView = MenuBarContentView()
            .environmentObject(appState)
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        // Create the status bar item with fixed width to ensure everything is visible
        self.statusItem = NSStatusBar.system.statusItem(withLength: 60)
        
        if let button = self.statusItem?.button {
            button.action = #selector(togglePopover)
            
            // Set initial state of button (will be updated by timer)
            updateStatusBarButton()
        }
        
        // Create a timer that updates the status bar display
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateStatusBarButton()
        }
        
        // Observe timer state changes to update the play/pause button
        NotificationCenter.default.addObserver(
            forName: .timerStateChanged,
            object: nil,
            queue: .main) { [weak self] _ in
                // Completely recreate the popover view controller to force a full refresh
                if let self = self, let popover = self.popover {
                    // Create a fresh SwiftUI view
                    let refreshedView = MenuBarContentView()
                        .environmentObject(self.appState)
                    
                    // Replace the content view controller
                    popover.contentViewController = NSHostingController(rootView: refreshedView)
                }
            }
            
        // Observe color setting changes to update the status bar
        NotificationCenter.default.addObserver(
            forName: .colorSettingsChanged,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.updateStatusBarButton()
            }
        
        // No notification permission needed
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func updateStatusBarButton() {
        guard let button = statusItem?.button else { return }
        
        // Remove all subviews first
        button.subviews.forEach { $0.removeFromSuperview() }
        
        // Create our custom view to display in the status bar
        let customView = NSView()
        button.addSubview(customView)
        customView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: button.topAnchor),
            customView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            customView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            customView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4)
        ])
        
        // Create horizontal stack
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 4
        customView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: customView.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: customView.trailingAnchor)
        ])
        
        // Add progress indicator (bar or pie)
        if appState.usePieChart {
            // Pie chart indicator
            let pieSize = NSSize(width: 16, height: 16)
            let pieView = NSView(frame: NSRect(origin: .zero, size: pieSize))
            
            // Create circular background
            let bgLayer = CAShapeLayer()
            let bgPath = CGPath(ellipseIn: CGRect(origin: .zero, size: pieSize), transform: nil)
            bgLayer.path = bgPath
            
            // Convert SwiftUI color to NSColor
            let emptyNSColor = NSColor(appState.emptyColor)
            bgLayer.fillColor = emptyNSColor.cgColor
            pieView.layer = CALayer()
            pieView.layer?.addSublayer(bgLayer)
            
            // Create progress indicator
            if appState.pomodoroTimer.progress > 0 {
                let progressLayer = CAShapeLayer()
                let angle = 2 * .pi * appState.pomodoroTimer.progress
                let path = CGMutablePath()
                
                // Start at center and move to top center
                path.move(to: CGPoint(x: pieSize.width/2, y: pieSize.height/2))
                path.addLine(to: CGPoint(x: pieSize.width/2, y: 0))
                
                // Add the arc
                path.addArc(center: CGPoint(x: pieSize.width/2, y: pieSize.height/2), 
                           radius: pieSize.width/2, 
                           startAngle: -.pi/2, 
                           endAngle: angle - .pi/2, 
                           clockwise: false)
                
                // Close back to center
                path.closeSubpath()
                
                progressLayer.path = path
                // Convert SwiftUI color to NSColor
                let fullNSColor = NSColor(appState.fullColor)
                progressLayer.fillColor = fullNSColor.cgColor
                pieView.layer?.addSublayer(progressLayer)
            }
            
            stackView.addArrangedSubview(pieView)
        } else {
            // Bar indicator 
            let barSize = NSSize(width: 8, height: 16)
            let barView = NSView(frame: NSRect(origin: .zero, size: barSize))
            
            // Create background
            let bgLayer = CAShapeLayer()
            let bgRect = CGRect(origin: .zero, size: barSize)
            bgLayer.path = CGPath(roundedRect: bgRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
            
            // Convert SwiftUI color to NSColor
            let emptyNSColor = NSColor(appState.emptyColor)
            bgLayer.fillColor = emptyNSColor.cgColor
            barView.layer = CALayer()
            barView.layer?.addSublayer(bgLayer)
            
            // Create progress indicator
            if appState.pomodoroTimer.progress > 0 {
                let progressHeight = max(1, barSize.height * appState.pomodoroTimer.progress)
                let progressRect = CGRect(x: 0, y: barSize.height - progressHeight, 
                                         width: barSize.width, height: progressHeight)
                
                let progressLayer = CAShapeLayer()
                progressLayer.path = CGPath(roundedRect: progressRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
                
                // Convert SwiftUI color to NSColor
                let fullNSColor = NSColor(appState.fullColor)
                progressLayer.fillColor = fullNSColor.cgColor
                barView.layer?.addSublayer(progressLayer)
            }
            
            stackView.addArrangedSubview(barView)
        }
        
        // Add time text if needed
        if appState.showMinutes || appState.showSeconds {
            let time = appState.pomodoroTimer.timeRemaining
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            
            var timeString = ""
            if appState.showMinutes && appState.showSeconds {
                timeString = String(format: "%02d:%02d", minutes, seconds)
            } else if appState.showMinutes {
                timeString = String(format: "%dm", minutes)
            } else if appState.showSeconds {
                // When only seconds are shown, display the total time in seconds
                let totalSeconds = Int(time)
                timeString = String(format: "%ds", totalSeconds)
            }
            
            let textField = NSTextField(labelWithString: timeString)
            textField.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            textField.alignment = .left
            textField.textColor = NSColor.labelColor
            
            stackView.addArrangedSubview(textField)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// Main entry point
@main
struct MacPomodoroApp {
    static func main() {
        if #available(macOS 11.0, *) {
            let app = NSApplication.shared
            let delegate = AppDelegate()
            app.delegate = delegate
            app.setActivationPolicy(.accessory)
            app.activate(ignoringOtherApps: true)
            app.run()
        } else {
            print("This app requires macOS 11.0 or later")
            exit(1)
        }
    }
}
