import Foundation
import NetworkExtension
import SwiftUI

struct InstallProfileButton: View {
    @Binding var parentIsLoading: Bool

    @State var errorPresented: Bool = false
    @State var errorMessage = ""

    var body: some View {
        Form {
            Button("Install tunnel profile") {
                Task {
                    await installProfile()
                }
            }
            .foregroundColor(.blue)
        }
        .alert(isPresented: $errorPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Ok"))
            )
        }
    }

    private func installProfile() async {
        do {
            _ = try await VPNProfile.install()
            parentIsLoading = true
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
            return
        }
    }
}
