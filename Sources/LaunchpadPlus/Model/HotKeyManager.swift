import Cocoa
import Carbon

@MainActor
class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onHotKeyPressed: (() -> Void)?
    
    private init() {
        setupEventHandler()
    }
    
    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let ptr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            var id = EventHotKeyID()
            GetEventParameter(event, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            
            if id.id == 1 {
                DispatchQueue.main.async {
                    manager.onHotKeyPressed?()
                }
                return OSStatus(noErr)
            }
            
            return OSStatus(eventNotHandledErr)
        }, 1, &eventType, ptr, &eventHandler)
    }
    
    func register(keyCode: Int, modifiers: Int) {
        // Force cleanup of any previous registration with the same ID
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        
        // Carbon registration is sensitive to timing when updating.
        // We use the same ID (1) to replace the existing hotkey globally for this signature.
        let hotKeyID = EventHotKeyID(signature: OSType(0x4c505031), id: 1) // 'LPP1'
        
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            print("HOTKEY UPDATE SUCCESS: KeyCode \(keyCode), Modifiers \(modifiers)")
        } else {
            print("HOTKEY UPDATE FAILED: Error code \(status)")
        }
    }
}
