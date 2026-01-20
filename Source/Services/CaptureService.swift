import Foundation
import ApplicationServices
import AppKit

/// Unified service for capturing text from any macOS application.
class CaptureService {
    static let shared = CaptureService()
    
    func captureContext() -> CaptureResult? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appName = frontmostApp.localizedName ?? ""
        let pid = frontmostApp.processIdentifier
        
        var result = CaptureResult(text: "", title: nil, url: nil, appName: appName)
        
        // 1. Try Browser Context (Title, URL, Content)
        if appName.contains("Safari") || appName.contains("Chrome") {
            if let context = getBrowserContext(appName: appName) {
                result.title = context.title
                result.url = context.url
                // If we have selected text, use it; otherwise, we might use the page content later
            }
        }
        
        // 2. Try specialized selection capture
        if let scriptText = getSelectedTextViaAppleScript(appName: appName), !scriptText.isEmpty {
            result.text = scriptText
            return result
        }
        
        // 3. Try Standard Accessibility
        let appElement = AXUIElementCreateApplication(pid)
        if let accText = getSelectedTextViaAccessibility(appElement), !accText.isEmpty {
            result.text = accText
            return result
        }
        
        // 4. Try Deep Recursive Scan
        if let deepText = findSelectedTextRecursively(in: appElement), !deepText.isEmpty {
            result.text = deepText
            return result
        }
        
        // 5. Final Fallback: Simulated Copy
        if let copyText = getSelectedTextViaCopyFallback(), !copyText.isEmpty {
            result.text = copyText
            return result
        }
        
        return result.text.isEmpty ? nil : result
    }
    
    struct CaptureResult {
        var text: String
        var title: String?
        var url: String?
        var appName: String
    }
    
    // --- Private logic ported from validated spikes ---
    
    private func getBrowserContext(appName: String) -> (title: String, url: String, content: String)? {
        let scriptSource: String
        if appName.contains("Safari") {
            scriptSource = """
            tell application "Safari"
                if (count of documents) > 0 then
                    set theURL to URL of document 1
                    set theTitle to name of window 1
                    set theContent to do JavaScript "document.body.innerText" in document 1
                    return theTitle & "|||" & theURL & "|||" & theContent
                else
                    return ""
                end if
            end tell
            """
        } else if appName.contains("Chrome") {
            scriptSource = """
            tell application "Google Chrome"
                if (count of windows) > 0 then
                    set theTitle to title of active tab of window 1
                    set theURL to url of active tab of window 1
                    set theContent to execute active tab of window 1 javascript "document.body.innerText"
                    return theTitle & "|||" & theURL & "|||" & theContent
                else
                    return ""
                end if
            end tell
            """
        } else {
            return nil
        }

        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let output = script.executeAndReturnError(&error)
            if error == nil, let resultString = output.stringValue {
                let parts = resultString.components(separatedBy: "|||")
                if parts.count >= 3 {
                    return (title: parts[0], url: parts[1], content: parts[2])
                }
            }
        }
        return nil
    }
    
    private func getSelectedTextViaAppleScript(appName: String) -> String? {
        let scriptSource: String
        if appName.contains("Safari") {
            scriptSource = "tell application \"Safari\" to do JavaScript \"window.getSelection().toString()\" in document 1"
        } else if appName.contains("Chrome") {
            scriptSource = "tell application \"Google Chrome\" to execute active tab of window 1 javascript \"window.getSelection().toString()\""
        } else if appName.contains("Microsoft Word") {
            scriptSource = "tell application \"Microsoft Word\" to get content of text object of selection"
        } else if appName.contains("Acrobat") {
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

    private func getSelectedTextViaAccessibility(_ appElement: AXUIElement) -> String? {
        var focusedElement: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success {
            let element = focusedElement as! AXUIElement
            var selectedText: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText) == .success, 
               let text = selectedText as? String, !text.isEmpty {
                return text
            }
        }
        return nil
    }

    private func findSelectedTextRecursively(in element: AXUIElement, depth: Int = 0) -> String? {
        if depth > 7 { return nil }
        var selectedText: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText) == .success, 
           let text = selectedText as? String, !text.isEmpty {
            return text
        }
        var children: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success, 
           let childrenArray = children as? [AXUIElement] {
            for child in childrenArray {
                if let found = findSelectedTextRecursively(in: child, depth: depth + 1) { return found }
            }
        }
        return nil
    }

    private func getSelectedTextViaCopyFallback() -> String? {
        let pasteboard = NSPasteboard.general
        let oldClipboard = pasteboard.string(forType: .string) ?? ""
        let oldChangeCount = pasteboard.changeCount
        
        simulateCopyCommand()
        
        for _ in 0...10 {
            Thread.sleep(forTimeInterval: 0.1)
            if pasteboard.changeCount != oldChangeCount {
                let newText = pasteboard.string(forType: .string)
                pasteboard.clearContents()
                pasteboard.setString(oldClipboard, forType: .string)
                return newText
            }
        }
        return nil
    }

    private func simulateCopyCommand() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let loc = CGEventTapLocation.cghidEventTap
        let cmdKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdKeyDown?.flags = .maskCommand
        cKeyDown?.flags = .maskCommand
        cmdKeyDown?.post(tap: loc)
        Thread.sleep(forTimeInterval: 0.01)
        cKeyDown?.post(tap: loc)
        Thread.sleep(forTimeInterval: 0.01)
        cKeyUp?.post(tap: loc)
        Thread.sleep(forTimeInterval: 0.01)
        cmdKeyUp?.post(tap: loc)
    }
}
