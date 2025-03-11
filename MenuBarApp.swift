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
        
        // Clear existing subviews
        button.subviews.forEach { $0.removeFromSuperview() }
        
        // Set appropriate length for status item
        if !(appState.showMinutes || appState.showSeconds) {
            statusItem?.length = 22 // Just the icon
        } else {
            statusItem?.length = 60 // Icon + text
        }
        
        // Create a clean, simple layout with NSBox as a container
        // NSBox lets us set a fixed height which will help maintain proper alignment
        let container = NSBox()
        container.boxType = .custom
        container.isTransparent = true
        container.titlePosition = .noTitle
        container.fillColor = NSColor.clear
        container.contentViewMargins = .zero
        
        // Fixed 22px height for menu bar
        container.frame = NSRect(x: 0, y: 0, width: statusItem!.length, height: 22)
        
        button.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Pin container to button
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: button.topAnchor),
            container.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: button.trailingAnchor)
        ])
        
        // Create a fixed-size, pre-positioned content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: statusItem!.length, height: 22))
        container.contentView = contentView
        
        // --- HORIZONTAL STACK ---
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        
        // Fixed spacing
        if appState.showMinutes && appState.showSeconds {
            stackView.spacing = 4  // Standard spacing when both shown
        } else if appState.showMinutes || appState.showSeconds {
            stackView.spacing = 2  // Reduced spacing with one field
        } else {
            stackView.spacing = 0  // No spacing when only showing chart
        }
        
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // These constraints are critical - they keep everything centered
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 2),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -2)
        ])
        
        // Horizontal positioning depends on content
        if !(appState.showMinutes || appState.showSeconds) {
            // Center when only showing chart
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            ])
        } else {
            // Left-align when showing text
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
                stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -2)
            ])
        }
        
        // --- CHART VIEW (PIE OR BAR) ---
        let chartView = NSView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        
        // Fix chart size - important for proper positioning
        if appState.usePieChart {
            NSLayoutConstraint.activate([
                chartView.widthAnchor.constraint(equalToConstant: 16),
                chartView.heightAnchor.constraint(equalToConstant: 16)
            ])
        } else {
            NSLayoutConstraint.activate([
                chartView.widthAnchor.constraint(equalToConstant: 8),
                chartView.heightAnchor.constraint(equalToConstant: 16)
            ])
        }
        
        // Draw the chart using layers - draw at the proper coordinate origin
        chartView.wantsLayer = true
        chartView.layer = CALayer()
        
        if appState.usePieChart {
            // PIE CHART
            let pieSize = NSSize(width: 16, height: 16)
            
            // Background circle - centered in view
            let bgLayer = CAShapeLayer()
            let circleRect = CGRect(x: 0, y: 0, width: pieSize.width, height: pieSize.height)
            bgLayer.path = CGPath(ellipseIn: circleRect, transform: nil)
            bgLayer.fillColor = NSColor(appState.emptyColor).cgColor
            chartView.layer?.addSublayer(bgLayer)
            
            // Draw progress only if there's progress to show
            if appState.pomodoroTimer.progress > 0 {
                // Create the progress layer
                let progressLayer = CAShapeLayer()
                
                // IMPORTANT: This angle calculation is critical for correct pie chart behavior
                // In Core Graphics coordinate system:
                // 0 radians = 3 o'clock
                // π/2 radians = 12 o'clock (top)
                // π radians = 9 o'clock
                // 3π/2 radians = 6 o'clock (bottom)
                
                // UX REQUIREMENT: Pie chart must start at 12 o'clock and fill clockwise
                // Start at 12 o'clock (π/2)
                let startAngle: CGFloat = CGFloat.pi/2
                
                // End angle for clockwise filling (MUST SUBTRACT progress to move clockwise)
                let endAngle: CGFloat = startAngle - (2 * CGFloat.pi * CGFloat(appState.pomodoroTimer.progress))
                
                // Create arc path
                let path = CGMutablePath()
                let center = CGPoint(x: pieSize.width/2, y: pieSize.height/2)
                
                // Move to center
                path.move(to: center)
                
                // Line to 12 o'clock position
                path.addLine(to: CGPoint(x: center.x, y: 0))
                
                // Add arc (clockwise=true in this coordinate system means clockwise visually)
                path.addArc(center: center,
                           radius: pieSize.width/2,
                           startAngle: startAngle,
                           endAngle: endAngle,
                           clockwise: true) // true = visually CLOCKWISE with this coordinate system
                
                // Close the path
                path.closeSubpath()
                
                // Apply to layer
                progressLayer.path = path
                progressLayer.fillColor = NSColor(appState.fullColor).cgColor
                chartView.layer?.addSublayer(progressLayer)
            }
        } else {
            // BAR CHART
            let barSize = NSSize(width: 8, height: 16)
            
            // Background bar
            let bgLayer = CAShapeLayer()
            let barRect = CGRect(x: 0, y: 0, width: barSize.width, height: barSize.height)
            bgLayer.path = CGPath(roundedRect: barRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
            bgLayer.fillColor = NSColor(appState.emptyColor).cgColor
            chartView.layer?.addSublayer(bgLayer)
            
            // Progress bar (filling up from the bottom)
            // UX FEATURE: The bar must always fill from bottom to top
            if appState.pomodoroTimer.progress > 0 {
                let progressHeight = max(1, barSize.height * appState.pomodoroTimer.progress)
                
                // Start from y=0 (bottom) and grow upward
                let progressRect = CGRect(x: 0, y: 0, width: barSize.width, height: progressHeight)
                
                let progressLayer = CAShapeLayer()
                progressLayer.path = CGPath(roundedRect: progressRect, 
                                          cornerWidth: 2, cornerHeight: 2, transform: nil)
                progressLayer.fillColor = NSColor(appState.fullColor).cgColor
                chartView.layer?.addSublayer(progressLayer)
            }
        }
        
        // Add chart to stack
        stackView.addArrangedSubview(chartView)
        
        // --- TEXT FIELD ---
        if appState.showMinutes || appState.showSeconds {
            // Calculate time components
            let time = appState.pomodoroTimer.timeRemaining
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            let totalSeconds = Int(time)
            
            // Format according to settings
            var timeString = ""
            if appState.showMinutes && appState.showSeconds {
                timeString = String(format: "%02d:%02d", minutes, seconds)
            } else if appState.showMinutes {
                timeString = String(format: "%dm", minutes)
            } else if appState.showSeconds {
                timeString = String(format: "%ds", totalSeconds)
            }
            
            // Create text field
            let textField = NSTextField(labelWithString: timeString)
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            textField.textColor = NSColor.labelColor
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.isEditable = false
            textField.alignment = .left
            
            // Add to stack
            stackView.addArrangedSubview(textField)
        }
    }
    // This code is commented out since we don't need the layout tester in production
    // Uncomment if needed for testing during development
    /*
    func showLayoutTester() {
        // The tester would be used during development
        // For production, we just apply the tested layout directly
    }
    */
    
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
