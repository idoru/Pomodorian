# Pomodorian Project Notes

## Build Commands

- Build application: `./build.sh`
- Run application: `open build/Pomodorian.app`

## App Structure

- `MenuBarApp.swift` - Main application entry point and AppKit integration
- `PomodoroTimer.swift` - Timer functionality and app state management
- `StatusBarView.swift` - Status bar UI components (SwiftUI)
- `MenuBarContentView.swift` - UI for menu bar dropdown (SwiftUI)
- `build.sh` - Builds the app bundle

## Project Conventions

- App name: `Pomodorian`
- Bundle identifier: `com.example.pomodorian`

## Implementation Notes

### Architecture

The application follows a hybrid architecture combining AppKit and SwiftUI:
- AppKit for low-level OS integration (status bar management)
- SwiftUI for UI components (popover menu)
- Custom drawing for status bar item (using CALayers)
- UserDefaults for persistent settings storage

### Persistence

The application persists user preferences using UserDefaults:
- Display settings (show minutes/seconds, use pie chart)
- Color settings (empty color, full color)
- Timer duration settings (minutes, seconds)

Color values are stored as individual RGB components since SwiftUI Color doesn't directly support serialization.

### Status Bar Implementation

The status bar item uses direct CALayer manipulation rather than embedded SwiftUI views, because:
- SwiftUI views embedded in NSStatusItem don't always update reliably
- Direct CALayer drawing gives more precise control over status bar appearance
- CALayers provide better performance for the constantly updating timer

### UX Requirements

These UX features must be maintained for consistency:
- Bar gauge must fill from bottom to top (not top to bottom)
- Pie chart must start empty and fill clockwise from the 12 o'clock position

### Core Graphics Notes

When working with the pie chart implementation, be aware of these important details:

1. Coordinate System: In CALayer/Core Graphics:
   - Origin (0,0) is at the top-left corner
   - Y-axis increases downward
   - X-axis increases to the right

2. Angle System for arcs:
   - 0 radians points to 3 o'clock
   - π/2 radians points to 12 o'clock
   - π radians points to 9 o'clock
   - 3π/2 radians points to 6 o'clock

3. To create a pie chart that fills clockwise starting from 12 o'clock:
   - Start angle must be π/2 (12 o'clock position)
   - End angle must decrease as progress increases (startAngle - progress*2π)
   - Use clockwise=true for the arc drawing
   - Initial line must go from center to (center.x, 0) which is the top edge

### UI Refresh Mechanism

Multiple UI refresh mechanisms ensure smooth updates:
1. Notification system for cross-component communication
2. Timer-based polling to refresh status bar (0.1s intervals)
3. SwiftUI state observers for reactive updates
4. Complete view recreation on important state changes

### Custom Components

- `TimerControlButton` - A specialized button that directly observes timer state
- Custom status bar drawing using Core Animation layers
- Custom notification names for app-specific events

### Key Learnings

1. **Status Bar Limitations**: SwiftUI views embedded in NSStatusItem buttons don't reliably refresh.
   Solution: Use direct AppKit/Core Animation for status bar rendering.

2. **UI Update Challenges**: Timer UI needs multiple refresh mechanisms.
   Solution: Implement redundant update strategies (polling + notifications + state changes).

3. **SwiftUI-AppKit Integration**: The boundary between SwiftUI and AppKit requires careful handling.
   Solution: Use NotificationCenter for cross-framework communication.

4. **State Propagation**: Race conditions can occur when updating UI from timer events.
   Solution: Complete view recreation for critical state changes.

5. **Color Management**: Converting between SwiftUI and AppKit color systems requires explicit conversion.
   Solution: Use NSColor(swiftUIColor) for conversion when working with CALayers.