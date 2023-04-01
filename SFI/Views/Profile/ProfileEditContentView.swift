import Foundation
import SwiftUI

struct ProfileEditContentView: View {
    let profile: ConfigProfile

    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @State private var isLoading = true

    @State private var profileContent: String = ""
    @State private var isChanged: Bool = false

    @State private var errorPresented: Bool = false
    @State private var errorMessage = ""

    var body: some View {
        viewBuilder {
            if isLoading {
                ProgressView().onAppear {
                    Task.detached {
                        loadContent()
                    }
                }
            } else {
                TextEditor(text: $profileContent)
                    .font(Font.system(.caption, design: .monospaced))
                    .padding()
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: profileContent) { _ in
                        isChanged = true
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
        .navigationBarTitle("Edit")
        .navigationBarItems(trailing: Button("Save") {
            Task.detached {
                await saveContent()
            }
        }.disabled(!isChanged))
    }

    private func loadContent() {
        do {
            profileContent = try profile.readContent()
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
        isLoading = false
    }

    private func saveContent() async {
        do {
            try profile.saveContent(profileContent)
            await MainActor.run {
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
    }
}
