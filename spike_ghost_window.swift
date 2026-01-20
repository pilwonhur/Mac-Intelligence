import Cocoa
import SwiftUI

// Spike #2: The "Ghost" Window
// This script creates a specialized 'NSPanel' that floats above other apps 
// WITHOUT stealing the input focus from the current application.

class GhostPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Key settings for "Ghost" behavior:
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Allow the window to be visible but not "Active" in the Dock sense
        self.becomesKeyOnlyIfNeeded = true 
        
        // Appearance
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .clear
        self.isMovableByWindowBackground = true
        
        // Glassmorphic effect (Vibrancy)
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .hudWindow // Changed from .ultraThinMaterial for AppKit compatibility
        self.contentView = visualEffect
    }
}

// A simple SwiftUI view to put inside our Ghost Window
struct GhostView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Mac Intelligence")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("I am a 'Ghost Window'.\nI am floating, but notice that your Terminal (or the underlying app) stays active!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Click Me") {
                print("Interaction works!")
            }
            .buttonStyle(.borderedProminent)
            
            Text("Press 'Close' or Cmd+Q to exit.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 300, height: 250)
    }
}

// Application Boilerplate to run this from a script
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: GhostPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panel = GhostPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 250))
        panel.center()
        
        // Host the SwiftUI View
        let hostingView = NSHostingView(rootView: GhostView())
        hostingView.frame = panel.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hostingView)
        
        panel.makeKeyAndOrderFront(nil)
        self.window = panel
        
        print("✅ Ghost Window Created.")
        print("Notice: The focus should stay on your Terminal!")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // This hides the app from the Dock
app.run()
