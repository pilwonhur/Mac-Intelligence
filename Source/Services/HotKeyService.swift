import Cocoa
import Carbon

/// Service for managing the global trigger hotkey.
class HotKeyService {
    static let shared = HotKeyService()
    private var hotKeyRef: EventHotKeyRef?
    private var action: (() -> Void)?
    
    func setup(action: @escaping () -> Void) {
        self.action = action
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D494349), id: 1) // 'MICI'
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_K)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
                HotKeyService.shared.action?()
                return noErr
            }, 1, &eventType, nil, nil)
        }
    }
}
