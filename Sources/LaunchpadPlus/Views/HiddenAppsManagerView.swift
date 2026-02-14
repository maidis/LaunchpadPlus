import SwiftUI

struct HiddenAppsManagerView: View {
    @ObservedObject var viewModel: AppListViewModel
    
    // We need to look up app info for hidden paths
    var hiddenApps: [(path: String, name: String)] {
        viewModel.hiddenPaths.map { path in
            let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
            return (path: path, name: name)
        }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        ZOceanModal {
            VStack(spacing: 0) {
                HStack {
                    Text(L10n.hiddenAppsTitle)
                        .font(.title2.bold())
                    Spacer()
                    Button(action: { viewModel.showingHiddenAppsManager = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                Divider().background(Color.white.opacity(0.2))
                
                if hiddenApps.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "eye")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(L10n.noHiddenApps)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(hiddenApps, id: \.path) { app in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(app.name)
                                            .font(.headline)
                                        Text(app.path)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(L10n.unhide) {
                                        viewModel.unhideApp(path: app.path)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
                
                Divider().background(Color.white.opacity(0.2))
                
                HStack {
                    Button(L10n.unhideAll) {
                        viewModel.unhideAllApps()
                        viewModel.showingHiddenAppsManager = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Spacer()
                    
                    Button(L10n.close) {
                        viewModel.showingHiddenAppsManager = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
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
        }
    }
}
