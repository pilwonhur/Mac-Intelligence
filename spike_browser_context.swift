import Foundation
import AppKit

// Spike #4: Browser Context Scraping
// This experiment tests how much additional context (Title + URL + Page Text) 
// we can extract from the active browser tab using AppleScript. 
// This allows the AI to understand the *full page* instead of just the selection.

func getBrowserContext() -> (title: String, url: String, content: String)? {
    guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return nil }
    let appName = frontmostApp.localizedName ?? ""
    
    let scriptSource: String
    if appName.contains("Safari") {
        scriptSource = """
        tell application "Safari"
            set theURL to URL of document 1
            set theTitle to name of window 1
            set theContent to do JavaScript "document.body.innerText" in document 1
            return theTitle & "|||" & theURL & "|||" & theContent
        end tell
        """
    } else if appName.contains("Chrome") {
        scriptSource = """
        tell application "Google Chrome"
            set theTitle to title of active tab of window 1
            set theURL to url of active tab of window 1
            set theContent to execute active tab of window 1 javascript "document.body.innerText"
            return theTitle & "|||" & theURL & "|||" & theContent
        end tell
        """
    } else {
        print("Not a supported browser: \(appName)")
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
        } else {
            print("AppleScript Error: \(String(describing: error))")
        }
    }
    return nil
}

print("--- Mac Intelligence: Spike #4 (Browser Context) ---")
print("Instructions:")
print("1. Switch to a webpage in Safari or Chrome.")
print("2. Wait 5 seconds for extraction...")

for i in (1...5).reversed() {
    print("\(i)...")
    Thread.sleep(forTimeInterval: 1.0)
}

if let context = getBrowserContext() {
    print("\n✅ Successfully extracted browser context:")
    print("---------------------------------")
    print("PAGE TITLE: \(context.title)")
    print("URL:        \(context.url)")
    print("CONTENT PREVIEW (First 500 chars):")
    print(String(context.content.prefix(500)))
    print("---------------------------------")
} else {
    print("\n❌ Failed to extract context.")
    print("Note: Ensure 'Allow JavaScript from Apple Events' is enabled in your browser's Developer menu.")
}
