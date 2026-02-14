import SwiftUI

struct HelpView: View {
    @ObservedObject var viewModel: AppListViewModel
    
    var body: some View {
        ZOceanModal(onClose: { viewModel.showingHelp = false }) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(L10n.helpTitle)
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
                        HelpSection(title: L10n.navigation, items: [
                            L10n.navItem1,
                            L10n.navItem2,
                            L10n.navItem3,
                            L10n.navItem4
                        ])
                        
                        HelpSection(title: L10n.folders, items: [
                            L10n.folderItem1,
                            L10n.folderItem2,
                            L10n.folderItem3
                        ])
                        
                        HelpSection(title: L10n.recentAppsHeader, items: [
                            L10n.recentAppsItem1,
                            L10n.recentAppsItem2
                        ])
                        
                        HelpSection(title: L10n.searchPlaceholder, items: [
                            L10n.searchItem1,
                            L10n.searchItem2
                        ])
                        
                        HelpSection(title: L10n.advanced, items: [
                            L10n.managementItem1,
                            L10n.managementItem2,
                            L10n.managementItem3,
                            L10n.managementItem4
                        ])
                        
                        HelpSection(title: L10n.proTips, items: [
                            L10n.proTipsItem1,
                            L10n.proTipsItem2
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
