import Foundation
import AppKit

final class AppScanner: @unchecked Sendable {
    static let shared = AppScanner()
    
    private let searchPaths = [
        "/Applications",
        "/System/Applications",
        FileManager.default.homeDirectoryForCurrentUser.path + "/Applications"
    ]
    
    func scanApps(includeUtilities: Bool = false) -> [AppItem] {
        var apps: [AppItem] = []
        let fileManager = FileManager.default
        
        var activePaths = searchPaths
        if includeUtilities {
            activePaths.append("/Applications/Utilities")
            activePaths.append("/System/Applications/Utilities")
        }
        
        for path in activePaths {
            guard let items = try? fileManager.contentsOfDirectory(atPath: path) else { continue }
            
            for item in items {
                if item.hasSuffix(".app") {
                    let fullPath = (path as NSString).appendingPathComponent(item)
                    let name = (item as NSString).deletingPathExtension
                    let icon = NSWorkspace.shared.icon(forFile: fullPath)
                    
                    // Apps in /System/Applications or root /Applications are generally not user-deletable in the same way
                    // But we'll mark apps NOT in /System/Applications as potentially deletable
                    let isSystem = fullPath.hasPrefix("/System")
                    let isDeletable = !isSystem
                    
                    apps.append(AppItem(name: name, path: fullPath, icon: icon, isDeletable: isDeletable))
                }
            }
        }
        
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
