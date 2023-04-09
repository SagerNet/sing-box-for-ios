import Libbox
import SwiftUI

struct SettingsView: View {
    @State var isLoading = true

    @State var includeAllNetworks: Bool = false
    @State var excludeLocalNetworks: Bool = true
    @State var enforceRoutes: Bool = false
    @State var disableMemoryLimit: Bool = false

    @State var version: String = ""

    let infoFont = Font.system(.caption, design: .monospaced)

    @State var dataSize: String = "Loading..."

    var body: some View {
        NavigationView {
            Form {
                if isLoading {
                    ProgressView().onAppear {
                        Task.detached {
                            loadSettings()
                        }
                    }
                } else {
                    #if DEBUG
                        Section("Debug") {
                            NavigationLink(destination: PProfServerSettingsView()) {
                                Text("PProf Server")
                            }
                            Button("Reset Database") {
                                Task.detached {
                                    FilePath.destroy()
                                }
                            }
                            .foregroundColor(.red)
                        }
                    #endif
                    Section("Packet Tunnel") {
                        Toggle("Include All Networks", isOn: $includeAllNetworks)
                            .onChange(of: includeAllNetworks) { newValue in
                                Task.detached {
                                    SharedPreferences.includeAllNetworks = newValue
                                }
                            }
                        Toggle("Exclude Local Networks", isOn: $excludeLocalNetworks)
                            .onChange(of: excludeLocalNetworks) { newValue in
                                Task.detached {
                                    SharedPreferences.excludeLocalNetworks = newValue
                                }
                            }
                        Toggle("Enforce Routes", isOn: $enforceRoutes)
                            .onChange(of: enforceRoutes) { newValue in
                                Task.detached {
                                    SharedPreferences.enforceRoutes = newValue
                                }
                            }
                        Toggle("Disable Memory Limit", isOn: $disableMemoryLimit)
                            .onChange(of: disableMemoryLimit) { newValue in
                                Task.detached {
                                    SharedPreferences.disableMemoryLimit = newValue
                                }
                            }
                    }
                    Section("Core") {
                        LineView(name: "Version", value: version)
                        LineView(name: "Data Size", value: dataSize)
                        NavigationLink(destination: ServiceLogView()) {
                            Text("View Service Log")
                        }
                        Button("Clear Working Directory") {
                            Task.detached {
                                clearWorkingDirectory()
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }.navigationViewStyle(.stack)
    }

    func loadSettings() {
        includeAllNetworks = SharedPreferences.includeAllNetworks
        excludeLocalNetworks = SharedPreferences.excludeLocalNetworks
        enforceRoutes = SharedPreferences.enforceRoutes
        disableMemoryLimit = SharedPreferences.disableMemoryLimit
        version = LibboxVersion()
        isLoading = false

        dataSize = (try? FilePath.workingDirectory.formattedSize()) ?? "Unknown"
    }

    func clearWorkingDirectory() {
        try? FileManager.default.removeItem(at: FilePath.workingDirectory)
        isLoading = true
    }
}
