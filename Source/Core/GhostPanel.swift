import Cocoa
import SwiftUI

/// A specialized NSPanel that floats and does not steal focus.
class GhostPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.minSize = NSSize(width: 300, height: 400)
        self.maxSize = NSSize(width: 1000, height: 1200)
        
        // Premium Configuration
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.becomesKeyOnlyIfNeeded = false
        
        // Borderless/Transparent Appearance
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .clear
        self.isMovableByWindowBackground = true
        self.hasShadow = true
        
        // High-Quality Materials
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .hudWindow 
        self.contentView = visualEffect
    }
    
    // Smooth fade-in
    func showWindow() {
        self.orderFrontRegardless()
        self.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 1.0
        }
    }
    
    // Smooth fade-out
    func closeWindow() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
        })
    }
}
