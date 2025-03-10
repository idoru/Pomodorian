import Cocoa
import SwiftUI

@available(macOS 11.0, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var timer: Timer?
    var contentView: NSHostingController<MenuBarContentView>?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let appState = AppState()
        
        // Create popover for menu
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        
        // Set up the SwiftUI views
        let contentView = MenuBarContentView()
            .environmentObject(appState)
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        // Create the status bar item
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = self.statusItem?.button {
            button.action = #selector(togglePopover)
            
            // Embed SwiftUI view for status bar
            let statusBarView = StatusBarView()
                .environmentObject(appState)
            let hostingView = NSHostingView(rootView: statusBarView)
            
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(hostingView)
            
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: button.topAnchor),
                hostingView.rightAnchor.constraint(equalTo: button.rightAnchor),
                hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                hostingView.leftAnchor.constraint(equalTo: button.leftAnchor)
            ])
        }
        
        // Start a timer to update the status bar
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if let button = self?.statusItem?.button {
                button.needsDisplay = true
            }
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