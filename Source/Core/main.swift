import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var state = AppState()
    var panel: GhostPanel?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 0. Load Settings
        state.apiKey = KeychainService.shared.get(key: "openai_api_key") ?? ""
        state.geminiKey = KeychainService.shared.get(key: "gemini_api_key") ?? ""
        
        if let savedProvider = UserDefaults.standard.string(forKey: "selected_provider"),
           let provider = AppState.AIProvider(rawValue: savedProvider) {
            state.selectedProvider = provider
        }
        
        setupMenu()
        
        // 1. Initialize Window (Start hidden)
        panel = GhostPanel(contentRect: NSRect(x: 0, y: 0, width: 350, height: 450))
        panel?.center()
        panel?.alphaValue = 0
        panel?.orderOut(nil)
        
        // 2. Setup SwiftUI View
        let hostingView = NSHostingView(rootView: MainView(state: state))
        hostingView.frame = panel!.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        panel?.contentView?.addSubview(hostingView)
        
        // 3. Setup Hotkey Service
        HotKeyService.shared.setup { [weak self] in
            self?.handleTrigger()
        }
        
        // 4. Observe visibility state
        state.$isPanelVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                if visible {
                    self?.panel?.showWindow()
                } else {
                    self?.panel?.closeWindow()
                }
            }
            .store(in: &cancellables)
        
        print("🚀 Mac Intelligence is running.")
        print("Trigger: Cmd + Shift + K")
    }
    
    func handleTrigger() {
        state.reset()
        
        // Start processing visually
        state.isPanelVisible = true
        
        // Capture Context (Text, Title, URL)
        if let result = CaptureService.shared.captureContext() {
            state.capturedText = result.text
            state.sourceTitle = result.title
            state.sourceURL = result.url
            state.appName = result.appName
        }
    }
    
    private func setupMenu() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit Mac Intelligence", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        mainMenu.addItem(appMenuItem)
        
        // Edit Menu (Crucial for Cmd+C/V/A)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        NSApplication.shared.mainMenu = mainMenu
    }
}

// Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // No Dock icon
app.run()
