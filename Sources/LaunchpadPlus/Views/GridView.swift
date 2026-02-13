import SwiftUI
import Combine

struct GridView: View {
    @ObservedObject var viewModel: AppListViewModel
    @StateObject private var inputManager = InputManager()
    @FocusState private var isSearchFocused: Bool
    @State private var redrawID = UUID()
    @State private var editingFolderName: String = ""
    @State private var isEditingFolderName: Bool = false
    @FocusState private var isRenameFocused: Bool
    
    var body: some View {
        let favorites = viewModel.favorites
        let pages = viewModel.pages
        let currentPageIndex = viewModel.currentPageIndex
        let selectedAppIndex = viewModel.selectedAppIndex
        let rows = viewModel.rows
        let cols = viewModel.cols
        
        return GeometryReader { geometry in
            ZStack {
                // 1. Full screen background blur
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .ignoresSafeArea()
                
                // 2. Click-to-hide background layer
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if !viewModel.isRecordingHotkey {
                            hideApp()
                        }
                    }

                // 3. Main Content
                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        Spacer()
                        
                        HStack {
                            TextField("Search", text: Binding(
                                get: { viewModel.searchText },
                                set: { viewModel.searchText = $0 }
                            ))
                            .textFieldStyle(PlainTextFieldStyle())
                            .focused($isSearchFocused)
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.searchText = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                        .frame(width: 300)
                        
                        Menu {
                            Text("Grid Settings")
                            Button("5 Rows") { viewModel.rows = 5 }
                            Button("6 Rows") { viewModel.rows = 6 }
                            Button("7 Rows") { viewModel.rows = 7 }
                            Divider()
                            Button("5 Cols") { viewModel.cols = 5 }
                            Button("7 Cols") { viewModel.cols = 7 }
                            Button("9 Cols") { viewModel.cols = 9 }
                            Divider()
                            Button(viewModel.includeUtilities ? "Hide Utilities" : "Show Utilities") {
                                viewModel.includeUtilities.toggle()
                            }
                            Divider()
                            Menu("Sort By") {
                                ForEach(AppListViewModel.SortOrder.allCases, id: \.self) { order in
                                    Button(order.rawValue) {
                                        viewModel.sortOrder = order
                                    }
                                }
                            }
                            Divider()
                            Menu("Hotkey Settings") {
                                Button(viewModel.isRecordingHotkey ? "Recording..." : "Change Shortcut (\(hotkeyLabel))") {
                                    viewModel.isRecordingHotkey.toggle()
                                }
                                Text("Current: \(hotkeyLabel)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Divider()
                            Menu("Advanced") {
                                Toggle("Launch at Login", isOn: $viewModel.launchAtLogin)
                                Divider()
                                Toggle("Show Recent Apps", isOn: $viewModel.showRecentlyOpened)
                                if viewModel.showRecentlyOpened {
                                    Picker("Recent Position", selection: $viewModel.recentlyOpenedPosition) {
                                        ForEach(AppListViewModel.RecentPosition.allCases, id: \.self) { pos in
                                            Text(pos.rawValue).tag(pos)
                                        }
                                    }
                                }
                                Divider()
                                Button("Manage Hidden Apps") {
                                    viewModel.showingHiddenAppsManager = true
                                }
                                Button("Unhide All Apps") {
                                    viewModel.unhideAllApps()
                                }
                            }
                            Divider()
                            Button("Help & Documentation") {
                                viewModel.showingHelp = true
                            }
                            Divider()
                            Button("Quit LaunchpadPlus", role: .destructive) {
                                NSApplication.shared.terminate(nil)
                            }
                        } label: {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .menuStyle(BorderlessButtonMenuStyle())
                        .frame(width: 30, height: 30)
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 10)
                    
                    // Calculation for layout
                    let totalAvailableHeight = geometry.size.height - 180 
                    let gridRows = viewModel.hasFavorites() ? max(1, rows - 1) : rows
                    let rowHeight = totalAvailableHeight / CGFloat(rows)

                    // Favorites & Recently Opened Row
                    if viewModel.hasFavorites() || (viewModel.showRecentlyOpened && viewModel.recentlyOpenedPosition == .side && !viewModel.recentlyOpenedApps.isEmpty) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                if viewModel.hasFavorites() {
                                    HStack(spacing: 15) {
                                        ForEach(favorites) { app in
                                            AppIconView(app: app, viewModel: viewModel, isFavorite: true, isSelected: false, size: rowHeight * 0.7)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                                        if let provider = providers.first {
                                            provider.loadObject(ofClass: NSString.self) { string, _ in
                                                if let appIDString = string as? String, let appID = UUID(uuidString: appIDString) {
                                                    DispatchQueue.main.async {
                                                        if let app = viewModel.allApps.first(where: { $0.id == appID }) {
                                                            viewModel.addToFavorites(app)
                                                        }
                                                    }
                                                }
                                            }
                                            return true
                                        }
                                        return false
                                    }
                                }
                                
                                if viewModel.showRecentlyOpened && viewModel.recentlyOpenedPosition == .side {
                                    let recents = viewModel.recentlyOpenedApps
                                    if !recents.isEmpty {
                                        Divider().background(Color.white.opacity(0.2))
                                            .frame(height: rowHeight * 0.6)
                                            .padding(.horizontal, 10)
                                            
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("RECENT")
                                                .font(.system(size: 9, weight: .black))
                                                .foregroundColor(.blue.opacity(0.7))
                                                .padding(.leading, 10)
                                            HStack(spacing: 10) {
                                                ForEach(recents) { app in
                                                    AppIconView(app: app, viewModel: viewModel, isFavorite: false, isSelected: false, size: rowHeight * 0.5)
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 20)
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(12)
                            .frame(minWidth: geometry.size.width, alignment: .center)
                        }
                        .frame(height: rowHeight + 10)
                        .onTapGesture { } // Prevent hiding
                    }
                    
                    if viewModel.showRecentlyOpened && viewModel.recentlyOpenedPosition == .bottom {
                        let recents = viewModel.recentlyOpenedApps
                        if !recents.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    Text("RECENT:")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.blue.opacity(0.8))
                                    ForEach(recents) { app in
                                        AppIconView(app: app, viewModel: viewModel, isFavorite: false, isSelected: false, size: rowHeight * 0.45)
                                    }
                                }
                                .padding(.horizontal)
                                .frame(minWidth: geometry.size.width, alignment: .center)
                            }
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.05))
                        }
                    }

                    // Main Grid
                    ZStack {
                        if pages.isEmpty {
                            Text("No apps found")
                                .foregroundColor(.white)
                        } else {
                            ForEach(0..<pages.count, id: \.self) { pageIndex in
                                if pageIndex == currentPageIndex {
                                    let apps = pages[pageIndex]
                                    LazyVGrid(
                                        columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: cols),
                                        spacing: 0
                                    ) {
                                        ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                                            let availableWidth = geometry.size.width / CGFloat(cols)
                                            let iconSize = min(availableWidth, rowHeight) * 0.7
                                            let isSelected = (index == selectedAppIndex)
                                            
                                            AppIconView(app: app, viewModel: viewModel, isFavorite: false, isSelected: isSelected, size: iconSize)
                                                .frame(width: availableWidth, height: rowHeight)
                                                .onDrag {
                                                    return NSItemProvider(object: app.id.uuidString as NSString)
                                                }
                                                .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                                                    if let provider = providers.first {
                                                        provider.loadObject(ofClass: NSString.self) { string, _ in
                                                            if let appIDString = string as? String, let appID = UUID(uuidString: appIDString) {
                                                                DispatchQueue.main.async {
                                                                    if appID != app.id {
                                                                        // Dropped on another app -> Folder creation
                                                                        viewModel.createFolder(with: appID, on: app.id)
                                                                    } else {
                                                                        // Dropped on itself or for move logic already handled by background?
                                                                        // Actually moveApp handle is on different level, but let's prioritize folder
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        return true
                                                    }
                                                    return false
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .frame(height: rowHeight * CGFloat(gridRows), alignment: .top)
                                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                                }
                            }
                        }
                    }
                    .onTapGesture { } // Prevent hiding when clicking on grid area
                    .frame(maxWidth: .infinity, maxHeight: rowHeight * CGFloat(gridRows))
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    if currentPageIndex < pages.count - 1 {
                                        withAnimation { viewModel.currentPageIndex += 1; viewModel.selectedAppIndex = nil }
                                    }
                                } else if value.translation.width > 50 {
                                    if currentPageIndex > 0 {
                                        withAnimation { viewModel.currentPageIndex -= 1; viewModel.selectedAppIndex = nil }
                                    }
                                }
                            }
                    )
                    
                    Spacer(minLength: 0)

                    // Bottom Pagination Dots
                    if pages.count > 1 {
                        HStack(spacing: 10) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPageIndex ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .onTapGesture {
                                        withAnimation {
                                            viewModel.currentPageIndex = index
                                            viewModel.selectedAppIndex = nil
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 20)
                        .padding(.top, 10)
                        .onTapGesture { } // Prevent hiding
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

                // 4. Hotkey Recording Dialog Overlay
                if viewModel.isRecordingHotkey {
                    ZOceanModal {
                        VStack(spacing: 25) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            VStack(spacing: 8) {
                                Text("Record New Shortcut")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                Text("1. Press your desired keys\n2. Click 'Save' to confirm\n(Manual restart required to activate)")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                            }
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 70)
                                
                                if let code = viewModel.pendingHotkeyKeyCode, let mods = viewModel.pendingHotkeyModifiers {
                                    Text(viewModel.hotkeyLabel(keyCode: code, modifiers: mods))
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text("Waiting for keys...")
                                        .font(.headline)
                                        .italic()
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                Button("Cancel") {
                                    viewModel.isRecordingHotkey = false
                                    viewModel.pendingHotkeyKeyCode = nil
                                    viewModel.pendingHotkeyModifiers = nil
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                
                                Button("Save Shortcut") {
                                    if let code = viewModel.pendingHotkeyKeyCode, let mods = viewModel.pendingHotkeyModifiers {
                                        viewModel.hotkeyKeyCode = code
                                        viewModel.hotkeyModifiers = mods
                                        viewModel.isRecordingHotkey = false
                                        viewModel.pendingHotkeyKeyCode = nil
                                        viewModel.pendingHotkeyModifiers = nil
                                        
                                        // No auto-restart as requested
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .disabled(viewModel.pendingHotkeyKeyCode == nil)
                                .tint(.blue)
                            }
                        }
                        .padding(40)
                        .background(
                            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 15)
                        .frame(width: 420)
                    }
                }

                if viewModel.showingHelp {
                    HelpView(viewModel: viewModel)
                }
                
                if viewModel.showingHiddenAppsManager {
                    HiddenAppsManagerView(viewModel: viewModel)
                }

                // 6. Folder Overlay
                if let folder = viewModel.openedFolder {
                    ZOceanModal(onClose: {
                        isEditingFolderName = false
                        viewModel.toggleFolder(nil)
                    }) {
                        VStack(spacing: 30) {
                            HStack {
                                if isEditingFolderName {
                                    TextField("Folder Name", text: $editingFolderName)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: 300)
                                        .focused($isRenameFocused)
                                        .onExitCommand {
                                            isEditingFolderName = false
                                        }
                                        .onSubmit {
                                            viewModel.renameFolder(oldName: folder.name, newName: editingFolderName)
                                            isEditingFolderName = false
                                        }
                                } else {
                                    HStack(spacing: 12) {
                                        Text(folder.name)
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Image(systemName: "pencil")
                                            .font(.title2)
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .onTapGesture {
                                        editingFolderName = folder.name
                                        isEditingFolderName = true
                                        isRenameFocused = true
                                    }
                                }
                                Spacer()
                                Button(action: { viewModel.dissolveFolder(folderName: folder.name) }) {
                                    HStack {
                                        Image(systemName: "pip.remove")
                                        Text("Dissolve Folder")
                                    }
                                    .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.trailing, 20)
                                
                                Button(action: { 
                                    isEditingFolderName = false
                                    viewModel.toggleFolder(nil) 
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 40)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 30) {
                                ForEach(folder.children) { child in
                                    AppIconView(app: child, viewModel: viewModel, isFavorite: false, isSelected: false, size: 80, inFolderName: folder.name)
                                }
                            }
                            .padding(40)
                        }
                        .frame(width: 600)
                        .background(
                            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 32))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(radius: 40)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .id(redrawID)
            .onAppear {
                inputManager.onKeyDown = { event in
                    if isEditingFolderName { return false }
                    
                    if viewModel.isRecordingHotkey {
                        if event.keyCode == 53 {
                            viewModel.isRecordingHotkey = false
                            viewModel.pendingHotkeyKeyCode = nil
                            viewModel.pendingHotkeyModifiers = nil
                            return true
                        }
                        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                        var carbonMods = 0
                        if modifiers.contains(.command) { carbonMods += 256 }
                        if modifiers.contains(.option) { carbonMods += 2048 }
                        if modifiers.contains(.shift) { carbonMods += 512 }
                        if modifiers.contains(.control) { carbonMods += 4096 }
                        let isSpecialKey = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63].contains(event.keyCode)
                        if !isSpecialKey {
                            viewModel.pendingHotkeyKeyCode = Int(event.keyCode)
                            viewModel.pendingHotkeyModifiers = carbonMods
                        }
                        return true
                    }
                    
                    if let char = event.characters, !isSearchFocused {
                        if event.keyCode == 123 { viewModel.selectPreviousApp(); return true }
                        else if event.keyCode == 124 { viewModel.selectNextApp(); return true }
                        else if event.keyCode == 126 { viewModel.selectAppUp(); return true }
                        else if event.keyCode == 125 { viewModel.selectAppDown(); return true }
                        else if event.keyCode == 36 { viewModel.launchSelectedApp(); return true }
                        else if event.keyCode == 53 {
                            hideApp()
                            return true
                        } else if event.keyCode == 51 {
                            if !viewModel.searchText.isEmpty { viewModel.searchText.removeLast() }
                            DispatchQueue.main.async { isSearchFocused = true }
                            return true
                        } else {
                            if !event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.control) {
                                if char.count == 1, let scalar = char.unicodeScalars.first, !NSCharacterSet.controlCharacters.contains(scalar) {
                                    viewModel.handleCharacterInput(char)
                                    isSearchFocused = true
                                    return true
                                }
                            }
                        }
                    }
                    return false
                }
            }
            .onChange(of: inputManager.scrollDelta) { delta in
                viewModel.handleScroll(delta: delta)
            }
            .onReceive(viewModel.objectWillChange) { _ in
                redrawID = UUID()
            }
            .task {
                isSearchFocused = false
            }
        }
    }

    private func hideApp() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.hideLaunchpad()
        } else {
            NSApplication.shared.hide(nil)
        }
    }

    private var hotkeyLabel: String {
        return viewModel.hotkeyLabel(keyCode: viewModel.hotkeyKeyCode, modifiers: viewModel.hotkeyModifiers)
    }
}

struct AppIconView: View {
    let app: AppItem
    let viewModel: AppListViewModel
    let isFavorite: Bool
    let isSelected: Bool
    let size: CGFloat
    var inFolderName: String? = nil
    
    @State private var isHovered = false
    
    var body: some View {
        VStack {
            ZStack {
                if app.isFolder {
                    // Folder Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            // Miniature previews of first 4 apps
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                                ForEach(app.children.prefix(4)) { child in
                                    Image(nsImage: child.icon)
                                        .resizable()
                                        .frame(width: size/3.2, height: size/3.2)
                                }
                            }
                            .padding(size/10)
                        )
                } else {
                    Image(nsImage: app.icon)
                        .resizable()
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(isHovered ? 1.15 : 1.0)
            .shadow(color: Color.blue.opacity(isHovered ? 0.3 : 0), radius: 10)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.6), lineWidth: isSelected ? 4 : 0)
            )
            
            Text(app.name)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: 80)
                .foregroundColor(.white)
                .background(isSelected ? Color.blue.opacity(0.6) : Color.clear)
                .cornerRadius(4)
        }
        .padding(5)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if app.isFolder {
                viewModel.toggleFolder(app)
            } else {
                viewModel.launchApp(app: app)
            }
        }
        .contextMenu {
            if isFavorite {
                Button("Remove from Favorites") { viewModel.removeFromFavorites(app) }
            } else {
                Button("Add to Favorites") { viewModel.addToFavorites(app) }
            }
            
            if !app.isFolder {
                Button("Hide App") {
                    viewModel.hideApp(app)
                }
            }
            
            if app.isDeletable && !app.isFolder {
                Divider()
                Button("Move to Trash") { viewModel.deleteApp(app) }.foregroundColor(.red)
            }
            
            if let folderName = inFolderName {
                Divider()
                Button("Move out of Folder") {
                    viewModel.removeAppFromFolder(app: app, folderName: folderName)
                }
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct ZOceanModal<Content: View>: View {
    let onClose: (() -> Void)?
    let content: Content
    
    init(onClose: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onClose = onClose
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onClose?()
                }
            content
                .onTapGesture { } // Prevent closing when clicking content
        }
    }
}
