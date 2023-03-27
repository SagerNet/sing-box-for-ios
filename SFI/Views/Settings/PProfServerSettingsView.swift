import Foundation
import SwiftUI

struct PProfServerSettingsView: View {
    @State var isLoading = true
    @State var pprofServerEnabled: Bool = false
    @State var pprofServerPort: Int = 8080

    let formatter = NumberFormatter()

    init() {
        formatter.minimum = 0
        formatter.maximum = 65535
    }

    var body: some View {
        Form {
            if isLoading {
                ProgressView().onAppear {
                    Task.detached {
                        loadSettings()
                    }
                }
            } else {
                Toggle("Enabled", isOn: $pprofServerEnabled)
                    .onChange(of: pprofServerEnabled) { newValue in
                        Task.detached {
                            SharedPreferences.pprofServerEnabled = newValue
                        }
                    }
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("0 - 65535", value: $pprofServerPort, formatter: formatter)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: pprofServerPort) { newValue in
                            Task.detached {
                                SharedPreferences.pprofServerPort = newValue
                            }
                        }
                }
            }
        }
        .navigationTitle("PProf Server")
    }

    private func loadSettings() {
        pprofServerEnabled = SharedPreferences.pprofServerEnabled
        pprofServerPort = SharedPreferences.pprofServerPort
        isLoading = false
    }
}
