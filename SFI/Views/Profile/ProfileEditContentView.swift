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
                    Task {
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
            Task {
                saveContent()
            }
        }.disabled(!isChanged))
    }

    private func loadContent() {
        do {
            profileContent = try String(contentsOfFile: profile.path)
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
        isLoading = false
    }

    private func saveContent() {
        do {
            try profileContent.write(toFile: profile.path, atomically: true, encoding: .utf8)
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
    }
}
