import Foundation
import ApplicationServices
import AppKit

// Spike #1.8: Adobe & Deep Scan (The Final Answer)
// Adobe Acrobat is notoriously difficult. This version combines:
// 1. Specialized AppleScript
// 2. Recursive Hierarchy Crawling
// 3. Robust Keyboard Simulation (with delay)

func simulateCopyCommand() {
    let source = CGEventSource(stateID: .combinedSessionState)
    let loc = CGEventTapLocation.cghidEventTap
    
    let cmdKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
    let cKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
    let cKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
    let cmdKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
    
    cmdKeyDown?.flags = .maskCommand
    cKeyDown?.flags = .maskCommand
    
    // Sequence with micro-delays for complex apps (Acrobat)
    cmdKeyDown?.post(tap: loc)
    Thread.sleep(forTimeInterval: 0.01) // 10ms delay
    cKeyDown?.post(tap: loc)
    Thread.sleep(forTimeInterval: 0.01)
    cKeyUp?.post(tap: loc)
    Thread.sleep(forTimeInterval: 0.01)
    cmdKeyUp?.post(tap: loc)
}

func getSelectedTextViaCopyFallback() -> String? {
    let pasteboard = NSPasteboard.general
    let oldClipboard = pasteboard.string(forType: .string) ?? ""
    let oldChangeCount = pasteboard.changeCount
    
    print("Executing Global Copy Fallback (Cmd+C)...")
    simulateCopyCommand()
    
    for _ in 0...10 {
        Thread.sleep(forTimeInterval: 0.1) // 100ms chunks for slower apps
        if pasteboard.changeCount != oldChangeCount {
            let newText = pasteboard.string(forType: .string)
            pasteboard.clearContents()
            pasteboard.setString(oldClipboard, forType: .string)
            return newText
        }
    }
    return nil
}

func findSelectedTextRecursively(in element: AXUIElement, depth: Int = 0) -> String? {
    if depth > 7 { return nil } // Limit depth for performance

    var selectedText: AnyObject?
    if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText) == .success, 
       let text = selectedText as? String, !text.isEmpty {
        return text
    }

    var children: AnyObject?
    if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success, 
       let childrenArray = children as? [AXUIElement] {
        for child in childrenArray {
            if let found = findSelectedTextRecursively(in: child, depth: depth + 1) {
                return found
            }
        }
    }
    return nil
}

func getSelectedTextViaAppleScript(appName: String) -> String? {
    let scriptSource: String
    if appName.contains("Safari") {
        scriptSource = "tell application \"Safari\" to do JavaScript \"window.getSelection().toString()\" in document 1"
    } else if appName.contains("Chrome") {
        scriptSource = "tell application \"Google Chrome\" to execute active tab of window 1 javascript \"window.getSelection().toString()\""
    } else if appName.contains("Microsoft Word") {
        scriptSource = "tell application \"Microsoft Word\" to get content of text object of selection"
    } else if appName.contains("Acrobat") {
        // Acrobat Pro/Reader specific (Requires 'Enable Accessibility' in Acrobat's own prefs)
        scriptSource = "tell application \"Adobe Acrobat Reader\" to return selected text of document 1"
    } else {
        return nil
    }

    var error: NSDictionary?
    if let script = NSAppleScript(source: scriptSource) {
        let output = script.executeAndReturnError(&error)
        if error == nil { return output.stringValue }
    }
    return nil
}

func getSelectedText() -> String? {
    guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return nil }
    let appName = frontmostApp.localizedName ?? ""
    let pid = frontmostApp.processIdentifier
    print("\nDetecting: \(appName) (PID: \(pid))")

    // 1. Specialized Apps
    if let text = getSelectedTextViaAppleScript(appName: appName), !text.isEmpty { return text }

    // 2. Focused Accessibility
    let appElement = AXUIElementCreateApplication(pid)
    var focusedElement: AnyObject?
    if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success {
        let element = focusedElement as! AXUIElement
        var accText: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &accText) == .success, 
           let text = accText as? String, !text.isEmpty {
            return text
        }
    }

    // 3. Deep Recursive Scan (Good for PDF viewers and complex UI)
    print("Focused element failed. Performing deep hierarchy crawl...")
    if let deepText = findSelectedTextRecursively(in: appElement), !deepText.isEmpty {
        return deepText
    }

    // 4. Global Fallback
    return getSelectedTextViaCopyFallback()
}

print("--- Mac Intelligence: Spike #1.8 (Adobe & Deep Scan) ---")

if !AXIsProcessTrusted() {
    print("⚠️  Accessibility Permission Required.")
    let _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
}

print("Instructions: Select text in Adobe Acrobat or any other app and wait 5 seconds...")

for i in (1...5).reversed() {
    print("\(i)...")
    Thread.sleep(forTimeInterval: 1.0)
}

if let capturedText = getSelectedText() {
    print("\n✅ Successfully captured text:")
    print("---------------------------------")
    print(capturedText)
    print("---------------------------------")
} else {
    print("\n❌ Failed to capture text.")
}
