import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppListViewModel: ObservableObject {
    @Published var apps: [AppItem] = []
    @Published var favorites: [AppItem] = [] {
        didSet {
             // Save flavor paths
             let paths = favorites.map { $0.path }
             UserDefaults.standard.set(paths, forKey: "favoritePaths")
             updatePages()
        }
    }
    @Published var pages: [[AppItem]] = []
    @Published var selectedAppIndex: Int? = nil
    @Published var includeUtilities: Bool = UserDefaults.standard.bool(forKey: "includeUtilities") {
        didSet {
            UserDefaults.standard.set(includeUtilities, forKey: "includeUtilities")
            refreshApps()
        }
    }
    enum SortOrder: String, CaseIterable {
        case alphabetical = "Alphabetical"
        case installDate = "Install Date"
        case mostUsed = "Most Used"
        case manual = "Manual"
    }
    
    @Published var sortOrder: SortOrder = SortOrder(rawValue: UserDefaults.standard.string(forKey: "sortOrder") ?? "Alphabetical") ?? .alphabetical {
        didSet {
            UserDefaults.standard.set(sortOrder.rawValue, forKey: "sortOrder")
            filterApps()
        }
    }
    @Published var appUsageCounts: [String: Int] = [:] // Path: Count
    @Published var hiddenPaths: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "hiddenPaths") ?? []) {
        didSet {
            UserDefaults.standard.set(Array(hiddenPaths), forKey: "hiddenPaths")
            refreshApps()
        }
    }
    @Published var openedFolder: AppItem? = nil
    @Published var showingHiddenAppsManager: Bool = false
    
    // Persistent folders: [FolderName: [AppPaths]]
    @Published var folderDefinitions: [String: [String]] = UserDefaults.standard.dictionary(forKey: "folderDefinitions") as? [String: [String]] ?? [:] {
        didSet {
            UserDefaults.standard.set(folderDefinitions, forKey: "folderDefinitions")
        }
    }
    
    // New Features
    @Published var recentlyOpenedPaths: [String] = UserDefaults.standard.stringArray(forKey: "recentlyOpenedPaths") ?? [] {
        didSet {
            UserDefaults.standard.set(recentlyOpenedPaths, forKey: "recentlyOpenedPaths")
        }
    }
    @Published var showRecentlyOpened: Bool = UserDefaults.standard.bool(forKey: "showRecentlyOpened") {
        didSet { UserDefaults.standard.set(showRecentlyOpened, forKey: "showRecentlyOpened") }
    }
    enum RecentPosition: String, CaseIterable {
        case side = "Side"
        case bottom = "Bottom"
    }
    @Published var recentlyOpenedPosition: RecentPosition = RecentPosition(rawValue: UserDefaults.standard.string(forKey: "recentlyOpenedPosition") ?? "Bottom") ?? .bottom {
        didSet { UserDefaults.standard.set(recentlyOpenedPosition.rawValue, forKey: "recentlyOpenedPosition") }
    }
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin(launchAtLogin)
        }
    }
    
    enum AppLanguage: String, CaseIterable {
        case system = "system"
        case en = "en"
        case tr = "tr"
        
        @MainActor
        var localizedName: String {
            switch self {
            case .system: return L10n.systemLanguage
            case .en: return "English"
            case .tr: return "Türkçe"
            }
        }
    }
    
    @Published var appLanguage: AppLanguage = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "system") ?? .system {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage")
            // Notify localization helper
            L10n.updateLanguage(appLanguage)
            objectWillChange.send()
        }
    }
    
    @Published var searchText: String = "" {
        didSet {
            // Avoid infinite loops if filterApps modifies searchText (it doesn't)
            // Perform filtering
             DispatchQueue.main.async { [weak self] in
                 self?.filterApps()
                 self?.currentPageIndex = 0
                 self?.selectedAppIndex = 0
             }
        }
    }
    
    // ... (rest of props)
    // We will use a separate InputManager in the View to drive this, or listen for events here.
    // For simplicity, let's expose methods that the View/InputManager calls.
    
    // Grid Configuration
    @Published var rows: Int = UserDefaults.standard.object(forKey: "gridRows") as? Int ?? 5 {
        didSet {
            UserDefaults.standard.set(rows, forKey: "gridRows")
            updatePages()
        }
    }
    @Published var cols: Int = UserDefaults.standard.object(forKey: "gridCols") as? Int ?? 7 {
        didSet {
            UserDefaults.standard.set(cols, forKey: "gridCols")
            updatePages()
        }
    }
    
    // HotKey Configuration
    // Default: Cmd(256) + Option(2048) = 2304. L = 37.
    @Published var hotkeyKeyCode: Int = UserDefaults.standard.integer(forKey: "hotkeyKeyCode") == 0 ? 37 : UserDefaults.standard.integer(forKey: "hotkeyKeyCode") {
        didSet {
            UserDefaults.standard.set(hotkeyKeyCode, forKey: "hotkeyKeyCode")
        }
    }
    @Published var hotkeyModifiers: Int = UserDefaults.standard.integer(forKey: "hotkeyModifiers") == 0 ? 2304 : UserDefaults.standard.integer(forKey: "hotkeyModifiers") {
        didSet {
            UserDefaults.standard.set(hotkeyModifiers, forKey: "hotkeyModifiers")
        }
    }
    
    @Published var isRecordingHotkey: Bool = false
    @Published var isRestarting: Bool = false
    @Published var showingHelp: Bool = false
    @Published var showingAbout: Bool = false
    @Published var pendingHotkeyKeyCode: Int? = nil
    @Published var pendingHotkeyModifiers: Int? = nil
    
    private var directoryWatcher: DirectoryWatcher?
    
    func hotkeyLabel(keyCode: Int, modifiers: Int) -> String {
        var label = ""
        if modifiers & 256 != 0 { label += "⌘" }
        if modifiers & 2048 != 0 { label += "⌥" }
        if modifiers & 4096 != 0 { label += "⌃" }
        if modifiers & 512 != 0 { label += "⇧" }
        
        // Simple mapping for common keys
        switch keyCode {
        case 0: label += "A"
        case 1: label += "S"
        case 2: label += "D"
        case 3: label += "F"
        case 8: label += "C"
        case 9: label += "V"
        case 11: label += "B"
        case 12: label += "Q"
        case 13: label += "W"
        case 14: label += "E"
        case 15: label += "R"
        case 17: label += "T"
        case 16: label += "Y"
        case 31: label += "O"
        case 35: label += "P"
        case 37: label += "L"
        case 38: label += "J"
        case 40: label += "K"
        case 45: label += "N"
        case 46: label += "M"
        case 49: label += "Space"
        case 36: label += "↩"
        case 48: label += "⇥"
        case 53: label += "⎋"
        default: label += String(format: "Key %X", keyCode)
        }
        return label
    }
    
    // Derived for pagination state in View, but we might need to track it here for keyboard nav
    @Published var currentPageIndex: Int = 0
    
    var allApps: [AppItem] = []
    
    var appsPerPage: Int {
        let actualRows = hasFavorites() ? max(1, rows - 1) : rows
        return actualRows * cols
    }
    
    init() {
        // Load persistent usage counts
        if let savedCounts = UserDefaults.standard.dictionary(forKey: "appUsageCounts") as? [String: Int] {
            self.appUsageCounts = savedCounts
        }
        
        // Load manual order if exists
        // (We will handle reconstruction after refreshApps/allApps is populated)
        
        setupDirectoryWatcher()
        
        // Initialize localization
        L10n.updateLanguage(appLanguage)
        
        refreshApps()
    }
    
    private func setupDirectoryWatcher() {
        let paths = [
            "/Applications",
            "/System/Applications",
            FileManager.default.homeDirectoryForCurrentUser.path + "/Applications"
        ]
        
        directoryWatcher = DirectoryWatcher(paths: paths) { [weak self] in
            print("Directory change detected, refreshing apps...")
            DispatchQueue.main.async {
                self?.refreshApps()
            }
        }
        directoryWatcher?.start()
    }
    
    // ... refreshApps ...

    func selectNextApp() {
        guard !pages.isEmpty else { return }
        let currentApps = pages[currentPageIndex]
        if let current = selectedAppIndex {
            if current < currentApps.count - 1 {
                selectedAppIndex = current + 1
            } else {
                // Next page (wrap around)
                currentPageIndex = (currentPageIndex + 1) % pages.count
                selectedAppIndex = 0
            }
        } else {
            selectedAppIndex = 0
        }
    }
    
    func selectPreviousApp() {
        guard !pages.isEmpty else { return }
        if let current = selectedAppIndex {
            if current > 0 {
                selectedAppIndex = current - 1
            } else {
                // Prev page (wrap around)
                currentPageIndex = (currentPageIndex - 1 + pages.count) % pages.count
                selectedAppIndex = pages[currentPageIndex].count - 1
            }
        } else {
             selectedAppIndex = 0
        }
    }
    
    func selectAppUp() {
       guard !pages.isEmpty, let current = selectedAppIndex else { selectedAppIndex = 0; return }
       let newIndex = current - cols
       if newIndex >= 0 {
           selectedAppIndex = newIndex
       } else {
           // Wrap to previous page
           currentPageIndex = (currentPageIndex - 1 + pages.count) % pages.count
           let currentApps = pages[currentPageIndex]
           // Try to go to the same column in the last row
           let lastRowStart = ((currentApps.count - 1) / cols) * cols
           let targetIndex = lastRowStart + (current % cols)
           selectedAppIndex = min(targetIndex, currentApps.count - 1)
       }
    }
    
    func selectAppDown() {
       guard !pages.isEmpty, let current = selectedAppIndex else { selectedAppIndex = 0; return }
       let currentApps = pages[currentPageIndex]
       let newIndex = current + cols
       if newIndex < currentApps.count {
           selectedAppIndex = newIndex
       } else {
           // Wrap to next page
           currentPageIndex = (currentPageIndex + 1) % pages.count
           // Go to same column in the first row
           let targetIndex = current % cols
           selectedAppIndex = min(targetIndex, pages[currentPageIndex].count - 1)
       }
    }
    
    func launchSelectedApp() {
        guard !pages.isEmpty, let index = selectedAppIndex else { return }
        let app = pages[currentPageIndex][index]
        launchApp(app: app)
    }
    
    func handleScroll(delta: CGFloat) {
        let pageCount = pages.count
        guard pageCount > 0 else { return }
        
        if delta > 0 { // Scroll Up -> Prev
            currentPageIndex = (currentPageIndex - 1 + pageCount) % pageCount
            selectedAppIndex = nil
        } else if delta < 0 { // Scroll Down -> Next
            currentPageIndex = (currentPageIndex + 1) % pageCount
            selectedAppIndex = nil
        }
    }
    
    func handleCharacterInput(_ char: String) {
        // If not empty, append to search
        // Allow all non-control characters
        if char.count == 1 {
            let isControl = char.rangeOfCharacter(from: .controlCharacters) != nil
            let isNewline = char.rangeOfCharacter(from: .newlines) != nil
            if !isControl && !isNewline {
                searchText.append(char)
            }
        }
    }
    
    func isSearchActive() -> Bool {
        return !searchText.isEmpty
    }
    
    func hasFavorites() -> Bool {
        return !favorites.isEmpty
    }
    
    func refreshApps() {
        let currentIncludeUtilities = includeUtilities
        let currentFolders = folderDefinitions
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var scannedApps = AppScanner.shared.scanApps(includeUtilities: currentIncludeUtilities)
            
            // Apply folder definitions
            var processedApps: [AppItem] = []
            var usedPaths = Set<String>()
            
            for (folderName, paths) in currentFolders {
                let children = scannedApps.filter { paths.contains($0.path) }
                if !children.isEmpty {
                    let folderIcon = NSWorkspace.shared.icon(for: .folder)
                    let folder = AppItem(
                        name: folderName,
                        path: "folder_\(folderName)", // Deterministic path for folders
                        icon: folderIcon,
                        isDeletable: true,
                        isFolder: true,
                        children: children
                    )
                    processedApps.append(folder)
                    usedPaths.formUnion(paths)
                }
            }
            
            // Add remaining apps
            scannedApps.removeAll { usedPaths.contains($0.path) }
            processedApps.append(contentsOf: scannedApps)
            
            DispatchQueue.main.async {
                self?.allApps = processedApps
                
                // Reconstruct manual order if saved
                if let savedOrder = UserDefaults.standard.stringArray(forKey: "appManualOrder") {
                    var orderedApps: [AppItem] = []
                    var remainingApps = processedApps
                    
                    for path in savedOrder {
                        if let index = remainingApps.firstIndex(where: { $0.path == path }) {
                            orderedApps.append(remainingApps.remove(at: index))
                        }
                    }
                    orderedApps.append(contentsOf: remainingApps)
                    self?.allApps = orderedApps
                }
                
                // Reconstruct favorites
                if let favoritePaths = UserDefaults.standard.stringArray(forKey: "favoritePaths") {
                    self?.favorites = favoritePaths.compactMap { path in
                        self?.allApps.first(where: { $0.path == path })
                    }
                }
                
                self?.filterApps()
            }
        }
    }
    
    func filterApps() {
        // First filter out hidden apps
        let visibleApps = allApps.filter { !hiddenPaths.contains($0.path) }
        
        applySorting(to: visibleApps)
    }
    
    private func applySorting(to sourceApps: [AppItem]) {
        let filtered: [AppItem]
        if searchText.isEmpty {
            filtered = sourceApps
        } else {
            filtered = sourceApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        var sorted = filtered
        switch sortOrder {
        case .alphabetical:
            sorted.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .installDate:
            sorted.sort { (app1, app2) -> Bool in
                let url1 = URL(fileURLWithPath: app1.path)
                let url2 = URL(fileURLWithPath: app2.path)
                
                let keys: Set<URLResourceKey> = [.addedToDirectoryDateKey, .creationDateKey]
                let values1 = try? url1.resourceValues(forKeys: keys)
                let values2 = try? url2.resourceValues(forKeys: keys)
                
                // Prioritize 'added to directory' date over creation date
                let date1 = values1?.addedToDirectoryDate ?? values1?.creationDate ?? .distantPast
                let date2 = values2?.addedToDirectoryDate ?? values2?.creationDate ?? .distantPast
                
                if date1 == date2 {
                    return app1.name.localizedCaseInsensitiveCompare(app2.name) == .orderedAscending
                }
                return date1 > date2 // Newest first
            }
        case .mostUsed:
            sorted.sort { (app1, app2) -> Bool in
                let count1 = appUsageCounts[app1.path] ?? 0
                let count2 = appUsageCounts[app2.path] ?? 0
                if count1 == count2 {
                    return app1.name.localizedCaseInsensitiveCompare(app2.name) == .orderedAscending
                }
                return count1 > count2
            }
        case .manual:
            // For manual, we just keep the order in 'allApps' which is modified by moveApp
            break
        }
        
        self.apps = sorted
        updatePages()
    }
    
    private func updatePages() {
        // Simple chunking logic
        pages = apps.chunked(into: appsPerPage)
    }
    
    func moveApp(from source: IndexSet, to destination: Int, inPage pageIndex: Int) {
        // Only allow manual move if sortOrder is manual and no search
        guard sortOrder == .manual, searchText.isEmpty else { return }
        
        var newAllApps = allApps
        
        // Items being moved
        let moveItems = source.map { pages[pageIndex][$0] }
        
        // Remove from allApps
        for item in moveItems {
            newAllApps.removeAll(where: { $0.id == item.id })
        }
        
        // Calculate insert index in allApps
        // This is simplified: it finds the item currently at the destination in the page and inserts before it
        let targetPageItems = pages[pageIndex]
        let insertGlobalIndex: Int
        if destination < targetPageItems.count {
            let targetItem = targetPageItems[destination]
            insertGlobalIndex = newAllApps.firstIndex(where: { $0.id == targetItem.id }) ?? newAllApps.count
        } else {
            // End of page or last page
            if pageIndex < pages.count - 1 {
                let nextPageItem = pages[pageIndex + 1][0]
                insertGlobalIndex = newAllApps.firstIndex(where: { $0.id == nextPageItem.id }) ?? newAllApps.count
            } else {
                insertGlobalIndex = newAllApps.count
            }
        }
        
        newAllApps.insert(contentsOf: moveItems, at: insertGlobalIndex)
        self.allApps = newAllApps
        
        // Save manual order
        saveManualOrder()
        
        filterApps()
    }

    func moveAppToPage(appID: UUID, toPageIndex: Int) {
        guard sortOrder == .manual, searchText.isEmpty else { return }
        var newAllApps = allApps
        guard let app = newAllApps.first(where: { $0.id == appID }) else { return }
        
        newAllApps.removeAll(where: { $0.id == appID })
        let insertIndex = min(toPageIndex * appsPerPage, newAllApps.count)
        newAllApps.insert(app, at: insertIndex)
        
        self.allApps = newAllApps
        
        // Save manual order
        let _ = newAllApps.map { $0.path }
        saveManualOrder()
        
        filterApps()
    }

    func addToFavorites(_ app: AppItem) {
        if !favorites.contains(where: { $0.id == app.id }) {
            favorites.append(app)
        }
    }
    
    func removeFromFavorites(_ app: AppItem) {
        favorites.removeAll(where: { $0.id == app.id })
    }
    
    func launchApp(app: AppItem) {
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.open(url)
        
        // Track usage and save to persistent storage
        appUsageCounts[app.path, default: 0] += 1
        UserDefaults.standard.set(appUsageCounts, forKey: "appUsageCounts")
        
        // Track recently opened
        var recents = recentlyOpenedPaths
        recents.removeAll { $0 == app.path }
        recents.insert(app.path, at: 0)
        recentlyOpenedPaths = Array(recents.prefix(5))
        
        if sortOrder == .mostUsed {
            filterApps()
        }
        
        // Automatically hide LaunchpadPlus after launching an app
        DispatchQueue.main.async {
            if let delegate = NSApp.delegate as? AppDelegate {
                delegate.hideLaunchpad()
            } else {
                NSApp.hide(nil)
            }
        }
    }

    func deleteApp(_ app: AppItem) {
        let url = URL(fileURLWithPath: app.path)
        
        // Use NSWorkspace to move to Trash (recycle)
        NSWorkspace.shared.recycle([url]) { (newURLs, error) in
            if let error = error {
                print("Error deleting app: \(error.localizedDescription)")
            } else {
                // Success: Update local list
                DispatchQueue.main.async {
                    self.allApps.removeAll(where: { $0.id == app.id })
                    self.favorites.removeAll(where: { $0.id == app.id })
                    self.applySorting(to: self.allApps)
                }
            }
        }
    }
    
    func hideApp(_ app: AppItem) {
        hiddenPaths.insert(app.path)
    }
    
    func unhideApp(path: String) {
        hiddenPaths.remove(path)
    }
    
    func unhideAllApps() {
        hiddenPaths.removeAll()
    }
    
    func toggleFolder(_ folder: AppItem?) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            openedFolder = folder
        }
    }
    
    func createFolder(with draggedAppID: UUID, on targetAppID: UUID) {
        guard let draggedApp = allApps.first(where: { $0.id == draggedAppID }),
              let targetApp = allApps.first(where: { $0.id == targetAppID }) else { return }
        
        if targetApp.isFolder {
            // Add to existing folder
            var paths = folderDefinitions[targetApp.name] ?? []
            if !paths.contains(draggedApp.path) {
                paths.append(draggedApp.path)
                folderDefinitions[targetApp.name] = paths
            }
        } else {
            // Create new folder
            // We'll use a unique enough name or just incremental
            let baseName = "New Folder"
            var folderName = baseName
            var count = 1
            while folderDefinitions[folderName] != nil {
                folderName = "\(baseName) \(count)"
                count += 1
            }
            
            folderDefinitions[folderName] = [targetApp.path, draggedApp.path]
        }
        
        saveManualOrder()
        refreshApps()
    }
    
    func renameFolder(oldName: String, newName: String) {
        guard !newName.isEmpty && oldName != newName else { return }
        guard let paths = folderDefinitions[oldName] else { return }
        
        // Remove old definition and add new one
        folderDefinitions.removeValue(forKey: oldName)
        folderDefinitions[newName] = paths
        
        // If the folder is currently open, update the openedFolder state
        if openedFolder?.name == oldName {
             refreshApps()
             // Wait for refresh to find the folder with the new name
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                 self.openedFolder = self.allApps.first(where: { $0.isFolder && $0.name == newName })
             }
        } else {
             refreshApps()
        }
    }
    
    func removeAppFromFolder(app: AppItem, folderName: String) {
        guard var paths = folderDefinitions[folderName] else { return }
        paths.removeAll { $0 == app.path }
        
        if paths.isEmpty {
            folderDefinitions.removeValue(forKey: folderName)
            toggleFolder(nil)
        } else {
            folderDefinitions[folderName] = paths
            // Update the opened folder model if it's currently open
            if openedFolder?.name == folderName {
                openedFolder?.children.removeAll { $0.path == app.path }
            }
        }
        
        refreshApps()
    }
    
    func dissolveFolder(folderName: String) {
        folderDefinitions.removeValue(forKey: folderName)
        toggleFolder(nil)
        refreshApps()
    }
    
    private func saveManualOrder() {
        // Note: Folders would need better persistence, for now let's just save the paths
        let orderPaths = allApps.map { $0.path }
        UserDefaults.standard.set(orderPaths, forKey: "appManualOrder")
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
    
    func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    var recentlyOpenedApps: [AppItem] {
        return recentlyOpenedPaths.compactMap { path in
            // Try to find in allApps or favorites (or re-scan if needed, but usually it's in allApps)
            allApps.first(where: { $0.path == path })
        }
    }
}
