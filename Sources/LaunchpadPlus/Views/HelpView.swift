import SwiftUI

struct HelpView: View {
    @ObservedObject var viewModel: AppListViewModel
    
    var body: some View {
        ZOceanModal(onClose: { viewModel.showingHelp = false }) {
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
                    VStack(alignment: .leading, spacing: 24) {
                        HelpSection(title: "Navigation", items: [
                            "Arrow Keys: Navigate through apps",
                            "Return: Launch selected application",
                            "Escape: Hide LaunchpadPlus",
                            "Trackpad Swipe/Wheel: Switch pages"
                        ])
                        
                        HelpSection(title: "Folders", items: [
                            "Create: Drag an app onto another to create a folder.",
                            "Rename: Click the folder name or the pencil icon inside an open folder.",
                            "Management: Move apps out via right-click or dissolve the entire folder using the header button."
                        ])
                        
                        HelpSection(title: "Recent Apps", items: [
                            "Displays your last 5 opened applications.",
                            "Configuration: Can be toggled and positioned (Side or Bottom) in Settings > Advanced."
                        ])
                        
                        HelpSection(title: "Search", items: [
                            "Start typing anywhere to search. Selection and copying are supported via mouse.",
                            "Clear: Click the close button or use Backspace."
                        ])
                        
                        HelpSection(title: "Management", items: [
                            "Favorites: Drag apps to the top bar or use context menu (Right-click).",
                            "Hide Apps: Use Context Menu > Hide App. Manage them in Settings > Advanced.",
                            "Uninstaller: Right-click any non-system app to move it to Trash."
                        ])
                        
                        HelpSection(title: "Pro Tips", items: [
                            "Background Click: Click any empty area to dismiss the app immediately.",
                            "Launch at Login: Enable in Advanced settings for a seamless startup experience (starts hidden)."
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
            Text(title.uppercased())
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.blue.opacity(0.8))
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.blue.opacity(0.5))
                        .padding(.top, 4)
                    Text(item)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
