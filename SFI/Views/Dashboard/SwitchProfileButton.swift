import NetworkExtension
import SwiftUI

struct SwitchProfileButton: View {
    @ObservedObject var profile: VPNProfile

    @Environment(\.togglePresented) var togglePresented

    @State var errorPresented: Bool = false
    @State var errorMessage = ""

    var body: some View {
        Toggle(isOn: Binding(get: {
            profile.status.isConnected
        }, set: { newValue, _ in
            Task.detached {
                await switchProfile(newValue)
            }
        })) {
            Text("Enabled")
        }
        .disabled(!profile.status.isEnabled || togglePresented.wrappedValue)
        .onChange(of: togglePresented.wrappedValue) { newValue in
            if newValue {
                Task.detached {
                    await toggleProfile()
                }
            }
        }
        .onAppear {
            if togglePresented.wrappedValue {
                Task.detached {
                    await toggleProfile()
                }
            }
        }
        .alert(isPresented: $errorPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Ok"))
            )
        }
    }

    private func toggleProfile() async {
        await switchProfile(profile.status == .disconnected)
        await MainActor.run {
            togglePresented.wrappedValue = false
        }
    }

    private func switchProfile(_ isEnabled: Bool) async {
        do {
            if isEnabled {
                try await profile.start()
            } else {
                profile.stop()
            }
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
            return
        }
    }
}

extension NEVPNStatus {
    var isEnabled: Bool {
        switch self {
        case .connected, .disconnected, .reasserting:
            return true
        default:
            return false
        }
    }

    var isSwitchable: Bool {
        switch self {
        case .connected, .disconnected:
            return true
        default:
            return false
        }
    }

    var isConnected: Bool {
        switch self {
        case .connecting, .connected, .disconnecting, .reasserting:
            return true
        default:
            return false
        }
    }
}
