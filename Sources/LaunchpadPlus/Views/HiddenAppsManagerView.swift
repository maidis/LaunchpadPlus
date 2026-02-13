import SwiftUI

struct HiddenAppsManagerView: View {
    @ObservedObject var viewModel: AppListViewModel
    
    // We need to look up app info for hidden paths
    var hiddenApps: [(path: String, name: String)] {
        // Since hidden apps aren't in viewModel.apps, we might need a way to find their names
        // For now, we'll try to find them in allApps or just use the filename
        viewModel.hiddenPaths.map { path in
            let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
            return (path: path, name: name)
        }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        ZOceanModal {
            VStack(spacing: 0) {
                HStack {
                    Text("Hidden Applications")
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
                        Text("No hidden applications")
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
                                    Button("Unhide") {
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
                    Button("Unhide All") {
                        viewModel.unhideAllApps()
                        viewModel.showingHiddenAppsManager = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Spacer()
                    
                    Button("Close") {
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
