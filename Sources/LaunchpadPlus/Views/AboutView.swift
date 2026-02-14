import SwiftUI

struct AboutView: View {
    @ObservedObject var viewModel: AppListViewModel
    
    var body: some View {
        ZOceanModal(onClose: { viewModel.showingAbout = false }) {
            VStack(spacing: 20) {
                // App Icon
                Image(nsImage: NSApplication.shared.applicationIconImage ?? NSImage())
                    .resizable()
                    .frame(width: 80, height: 80)
                    .shadow(radius: 10)
                
                VStack(spacing: 5) {
                    Text("LaunchpadPlus")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text(L10n.versionInfo("1.2.0"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Divider().background(Color.white.opacity(0.1)).frame(width: 200)
                
                VStack(spacing: 15) {
                    Text(L10n.appDescription)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 40)
                    
                    Text(L10n.craftedWith)
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.7))
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("© 2026")
                        Link("maidis/LaunchpadPlus", destination: URL(string: "https://github.com/maidis/LaunchpadPlus")!)
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    
                    Button(L10n.close) {
                        viewModel.showingAbout = false
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.bottom, 20)
            }
            .frame(width: 400, height: 450)
            .background(
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 40)
        }
    }
}
