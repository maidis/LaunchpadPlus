import SwiftUI

struct HelpView: View {
    @ObservedObject var viewModel: AppListViewModel
    
    var body: some View {
        ZOceanModal {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("LaunchpadPlus Help")
                        .font(.title2.bold())
                    Spacer()
                    Button(action: { viewModel.showingHelp = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                Divider().background(Color.white.opacity(0.2))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HelpSection(title: "Navigation", items: [
                            "Arrow Keys: Navigate through apps",
                            "Return: Launch selected application",
                            "Escape: Hide LaunchpadPlus",
                            "Trackpad Swipe: Switch pages",
                            "Scroll Wheel: Switch pages"
                        ])
                        
                        HelpSection(title: "Search", items: [
                            "Start typing any characters to search for apps immediately.",
                            "Backspace: Remove last character from search",
                            "Clear Search: Click the X button in search bar"
                        ])
                        
                        HelpSection(title: "Management", items: [
                            "Drag and Drop: Rearrange apps (Manual sort mode required)",
                            "Right Click: Add to favorites or move app to Trash",
                            "Settings: Access grid size, sorting, and hotkey options via the gear icon"
                        ])
                        
                        HelpSection(title: "Global Shortcut", items: [
                            "Change the activation shortcut in Settings > Hotkey Settings.",
                            "A manual application restart is required after changing the shortcut."
                        ])
                        
                        HelpSection(title: "Background", items: [
                            "Click anywhere on the empty background to dismiss LaunchpadPlus."
                        ])
                    }
                    .padding()
                }
            }
            .frame(width: 500, height: 600)
            .background(
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 15)
        }
    }
}

struct HelpSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }
}
