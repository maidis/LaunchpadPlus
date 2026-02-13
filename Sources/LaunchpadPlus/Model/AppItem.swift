import Foundation
import AppKit

struct AppItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let icon: NSImage
    let isDeletable: Bool
    var isFolder: Bool = false
    var children: [AppItem] = []
    
    init(id: UUID = UUID(), name: String, path: String, icon: NSImage, isDeletable: Bool, isFolder: Bool = false, children: [AppItem] = []) {
        self.id = id
        self.name = name
        self.path = path
        self.icon = icon
        self.isDeletable = isDeletable
        self.isFolder = isFolder
        self.children = children
    }
    
    // Conformance to Hashable for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        return lhs.id == rhs.id
    }
}
