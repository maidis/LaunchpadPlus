import SwiftUI
import AppKit

@main
struct LaunchpadPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class FullScreenWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: FullScreenWindow!
    let viewModel = AppListViewModel()
    private var userWantsVisibility = true

    func applicationWillFinishLaunching(_ notification: Notification) {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.LaunchpadPlus"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        
        // If there's more than one instance (this one + another), quit the new one
        if runningApps.count > 1 {
            print("Another instance is already running. Quitting.")
            NSApp.terminate(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        let contentView = GridView(viewModel: viewModel)
        
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenRect = screen.frame
        
        window = FullScreenWindow(
            contentRect: screenRect,
            // Add fullSizeContentView to ensure layout hits the very top
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = NSHostingView(rootView: contentView.ignoresSafeArea())
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        
        // Use a level that is definitely above the menu bar
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        
        // Ensure initial frame covers everything
        window.setFrame(screenRect, display: true)
        
        setupGlobalHotKey()
        viewModel.checkLaunchAtLoginStatus()
        // Removed: showLaunchpad() - start hidden as requested
    }
    
    private func setupGlobalHotKey() {
        updateGlobalHotKey()
        HotKeyManager.shared.onHotKeyPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.toggleLaunchpad()
            }
        }
    }
    
    func updateGlobalHotKey() {
        let keyCode = viewModel.hotkeyKeyCode
        let modifiers = viewModel.hotkeyModifiers
        print("Updating HotKey to: \(keyCode) with mods \(modifiers)")
        HotKeyManager.shared.register(keyCode: keyCode, modifiers: modifiers)
    }
    
    func toggleLaunchpad() {
        if userWantsVisibility && window.isVisible {
            hideLaunchpad()
        } else {
            showLaunchpad()
        }
    }
    
    func showLaunchpad() {
        print("Show Launchpad requested")
        
        // Find the screen containing the mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let targetScreen = screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? screens[0]
        let screenRect = targetScreen.frame
        
        // Update window frame to target screen
        window.setFrame(screenRect, display: true)
        
        userWantsVisibility = true
        // Use hideMenuBar instead of autoHide for a more fixed "cover" feeling
        NSApp.presentationOptions = [.hideMenuBar, .hideDock]
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideLaunchpad() {
        print("Hide Launchpad requested")
        userWantsVisibility = false
        window.orderOut(nil)
        NSApp.presentationOptions = []
        // We don't use NSApp.hide(nil) here to avoid the OS auto-unhiding us
        // Instead we just deactivate to let the previous app or newly opened app take focus
        NSApp.deactivate()
    }
    
    func relaunchApp() {
        let bundlePath = Bundle.main.bundlePath
        
        // Final sync of settings
        UserDefaults.standard.synchronize()
        
        // Direct shell command to open a new instance and exit
        let shellCommand = "open -n \"\(bundlePath)\""
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", shellCommand]
        
        do {
            try task.run()
            // Immediate exit to free up the system listener
            exit(0)
        } catch {
            // Last resort
            NSWorkspace.shared.open(URL(fileURLWithPath: bundlePath))
            exit(0)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("Application reopen requested, hasVisibleWindows: \(flag)")
        showLaunchpad()
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("Application became active, userWantsVisibility: \(userWantsVisibility)")
        if userWantsVisibility {
            NSApp.presentationOptions = [.hideMenuBar, .hideDock]
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
            }
        } else {
            // If the OS auto-activated us but we don't want to be shown,
            // ensure we stay hidden and yield focus.
            window.orderOut(nil)
            NSApp.presentationOptions = []
        }
    }

    func applicationDidResignActive(_ notification: Notification) {
        print("Application resigned active, userWantsVisibility: \(userWantsVisibility)")
        NSApp.presentationOptions = []
        // If we lost focus not by our own hideLaunchpad() call, 
        // we should respect that and stay hidden but set userWantsVisibility to false
        // so we don't pop up again when whatever app the user switched to closes.
        if !userWantsVisibility {
            window.orderOut(nil)
        } else {
            // User likely alt-tabbed or clicked away
            userWantsVisibility = false
            window.orderOut(nil)
        }
    }
}
