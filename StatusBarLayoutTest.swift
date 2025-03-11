import Cocoa
import SwiftUI

/*
 This file contains a test harness for status bar layout testing.
 It creates a window that shows all possible status bar layout combinations,
 allowing us to verify the layout is correct before integrating into the app.
 */

@available(macOS 11.0, *)
class StatusBarLayoutTest: NSObject {
    var window: NSWindow?
    
    // Test all layout combinations
    func runTest() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Status Bar Layout Test"
        let contentView = NSView()
        window?.contentView = contentView
        
        // Create different combinations to test
        let testConfigs = [
            // Test 1: No text, just pie
            TestConfig(showMinutes: false, showSeconds: false, usePieChart: true, progress: 0.7),
            
            // Test 2: No text, just bar
            TestConfig(showMinutes: false, showSeconds: false, usePieChart: false, progress: 0.7),
            
            // Test 3: Minutes only, pie
            TestConfig(showMinutes: true, showSeconds: false, usePieChart: true, progress: 0.7),
            
            // Test 4: Seconds only, pie
            TestConfig(showMinutes: false, showSeconds: true, usePieChart: true, progress: 0.7),
            
            // Test 5: Both minutes and seconds, pie
            TestConfig(showMinutes: true, showSeconds: true, usePieChart: true, progress: 0.7),
            
            // Test 6: Minutes only, bar
            TestConfig(showMinutes: true, showSeconds: false, usePieChart: false, progress: 0.7),
            
            // Test 7: Seconds only, bar
            TestConfig(showMinutes: false, showSeconds: true, usePieChart: false, progress: 0.7),
            
            // Test 8: Both minutes and seconds, bar
            TestConfig(showMinutes: true, showSeconds: true, usePieChart: false, progress: 0.7)
        ]
        
        // Create a vertical layout for all test cases
        let outerStackView = NSStackView()
        outerStackView.orientation = .vertical
        outerStackView.alignment = .leading
        outerStackView.spacing = 20
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(outerStackView)
        
        NSLayoutConstraint.activate([
            outerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            outerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            outerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            outerStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Add each test configuration
        for (index, config) in testConfigs.enumerated() {
            let rowStack = NSStackView()
            rowStack.orientation = .horizontal
            rowStack.spacing = 10
            
            // Add label describing the test case
            let label = NSTextField(labelWithString: "Test \(index + 1): \(config.description)")
            label.preferredMaxLayoutWidth = 200
            label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            rowStack.addArrangedSubview(label)
            
            // Add a visual separator
            let separator = NSBox()
            separator.boxType = .separator
            rowStack.addArrangedSubview(separator)
            
            // Create the actual status bar mockup
            let mockupView = createStatusBarMockup(with: config)
            rowStack.addArrangedSubview(mockupView)
            
            outerStackView.addArrangedSubview(rowStack)
        }
        
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
    
    // Create a mockup of the status bar with the given configuration
    private func createStatusBarMockup(with config: TestConfig) -> NSView {
        // Create a container that mimics a status bar item
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.darkGray.cgColor
        container.layer?.cornerRadius = 4
        
        // Set fixed height to match menu bar
        let height: CGFloat = 22
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: height)
        ])
        
        // Width depends on content
        if !config.showMinutes && !config.showSeconds {
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 22)
            ])
        } else {
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 60)
            ])
        }
        
        // IMPLEMENTATION OF STATUS BAR LAYOUT GOES HERE
        // This should match exactly what we plan to use in MenuBarApp.swift
        
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 4
        
        // Set spacing based on what text is shown
        if config.showMinutes && config.showSeconds {
            stackView.spacing = 4
        } else if config.showMinutes || config.showSeconds {
            stackView.spacing = 2
        } else {
            stackView.spacing = 0
        }
        
        // Add stack view to container
        container.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // THIS IS THE CRITICAL PART - Positioning
        NSLayoutConstraint.activate([
            // Center vertically
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            // Horizontal positioning
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 3),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -3)
        ])
        
        // --- CREATE CHART VIEW ---
        let chartSize = config.usePieChart ? NSSize(width: 16, height: 16) : NSSize(width: 8, height: 16)
        let chartView = NSView(frame: NSRect(origin: .zero, size: chartSize))
        chartView.wantsLayer = true
        
        if config.usePieChart {
            // Create pie chart
            let bgLayer = CAShapeLayer()
            bgLayer.path = CGPath(ellipseIn: CGRect(origin: .zero, size: chartSize), transform: nil)
            bgLayer.fillColor = NSColor.systemGray.cgColor
            
            chartView.layer = CALayer()
            chartView.layer?.addSublayer(bgLayer)
            
            // Progress indicator
            if config.progress > 0 {
                let progressLayer = CAShapeLayer()
                let angle = 2 * .pi * config.progress
                let path = CGMutablePath()
                
                path.move(to: CGPoint(x: chartSize.width/2, y: chartSize.height/2))
                path.addLine(to: CGPoint(x: chartSize.width/2, y: 0))
                path.addArc(center: CGPoint(x: chartSize.width/2, y: chartSize.height/2),
                           radius: chartSize.width/2,
                           startAngle: -.pi/2,
                           endAngle: angle - .pi/2,
                           clockwise: true)
                path.closeSubpath()
                
                progressLayer.path = path
                progressLayer.fillColor = NSColor.systemRed.cgColor
                chartView.layer?.addSublayer(progressLayer)
            }
        } else {
            // Create bar chart
            let bgLayer = CAShapeLayer()
            bgLayer.path = CGPath(roundedRect: CGRect(origin: .zero, size: chartSize),
                                cornerWidth: 2, cornerHeight: 2, transform: nil)
            bgLayer.fillColor = NSColor.systemGray.cgColor
            
            chartView.layer = CALayer()
            chartView.layer?.addSublayer(bgLayer)
            
            // Progress indicator
            if config.progress > 0 {
                let progressHeight = max(1, chartSize.height * config.progress)
                let progressRect = CGRect(x: 0, y: 0, width: chartSize.width, height: progressHeight)
                
                let progressLayer = CAShapeLayer()
                progressLayer.path = CGPath(roundedRect: progressRect,
                                          cornerWidth: 2, cornerHeight: 2, transform: nil)
                progressLayer.fillColor = NSColor.systemRed.cgColor
                chartView.layer?.addSublayer(progressLayer)
            }
        }
        
        // Add chart to stack view
        stackView.addArrangedSubview(chartView)
        
        // Add text if needed
        if config.showMinutes || config.showSeconds {
            let timeString: String
            if config.showMinutes && config.showSeconds {
                timeString = "25:00"
            } else if config.showMinutes {
                timeString = "25m"
            } else {
                timeString = "1500s"
            }
            
            let textField = NSTextField(labelWithString: timeString)
            textField.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            textField.textColor = NSColor.white
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.isEditable = false
            
            stackView.addArrangedSubview(textField)
        }
        
        return container
    }
}

// Configuration for each test case
struct TestConfig {
    let showMinutes: Bool
    let showSeconds: Bool
    let usePieChart: Bool
    let progress: Double
    
    var description: String {
        var parts: [String] = []
        
        if showMinutes && showSeconds {
            parts.append("Minutes+Seconds")
        } else if showMinutes {
            parts.append("Minutes only")
        } else if showSeconds {
            parts.append("Seconds only")
        } else {
            parts.append("No text")
        }
        
        parts.append(usePieChart ? "Pie chart" : "Bar chart")
        
        return parts.joined(separator: ", ")
    }
}
