import Foundation
import Carbon

class DirectoryWatcher {
    private var stream: FSEventStreamRef?
    private let callback: () -> Void
    private let paths: [String]
    private var lastTriggerTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 2.0 // Refresh at most every 2 seconds
    
    init(paths: [String], callback: @escaping () -> Void) {
        self.paths = paths
        self.callback = callback
    }
    
    func start() {
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        
        let streamingCallback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            let watcher = Unmanaged<DirectoryWatcher>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
            watcher.handleEvent()
        }
        
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            streamingCallback,
            &context,
            paths as CFArray,
            UInt64(kFSEventStreamEventIdSinceNow),
            1.0, // Latency in seconds
            UInt32(kFSEventStreamCreateFlagNone | kFSEventStreamCreateFlagFileEvents)
        )
        
        FSEventStreamScheduleWithRunLoop(stream!, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream!)
    }
    
    func stop() {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }
    
    private func handleEvent() {
        let now = Date()
        if now.timeIntervalSince(lastTriggerTime) > debounceInterval {
            lastTriggerTime = now
            callback()
        }
    }
    
    deinit {
        stop()
    }
}
