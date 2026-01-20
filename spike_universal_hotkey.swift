import Cocoa
import Carbon

// Spike #3: Universal Hotkey
// This script registers a global hotkey (Cmd+Shift+K) that works even when 
// the app is in the background. It uses the Carbon framework, which is the 
// standard for low-level global hotkey registration on macOS.

class HotKeyHandler {
    static let shared = HotKeyHandler()
    
    func registerHotKey() {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x12345678), id: 1)
        
        // Register Cmd + Shift + K (kVK_ANSI_K = 40)
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_K)
        
        print("Registering Global Hotkey: Cmd + Shift + K")
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            print("✅ Hotkey registered successfully.")
            
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            
            // Use the actual InstallEventHandler function instead of the macro
            InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
                print("\n🔥 Hotkey Pressed!")
                return noErr
            }, 1, &eventType, nil, nil)
            
        } else {
            print("❌ Failed to register hotkey. Status code: \(status)")
        }
    }
}

print("--- Mac Intelligence: Spike #3 (Universal Hotkey) ---")
print("Press 'Cmd + Shift + K' to test.")
print("Press 'Ctrl + C' in Terminal to exit.")

let app = NSApplication.shared
HotKeyHandler.shared.registerHotKey()
app.run()
