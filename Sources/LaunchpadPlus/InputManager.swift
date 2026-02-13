import SwiftUI
import AppKit

class InputManager: ObservableObject {
    @Published var scrollDelta: CGFloat = 0
    var onKeyDown: ((NSEvent) -> Bool)?
    
    private var monitor: Any?
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .scrollWheel]) { [weak self] event in
            if event.type == .scrollWheel {
                let deltaY = event.deltaY
                let deltaX = event.deltaX
                if abs(deltaY) > 0.5 || abs(deltaX) > 0.5 {
                    self?.scrollDelta = deltaY != 0 ? deltaY : deltaX
                }
                return event
            } else if event.type == .keyDown {
                if self?.onKeyDown?(event) == true {
                    return nil // Consume event
                }
                return event
            }
            return event
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
