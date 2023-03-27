import Foundation
import SwiftUI

struct ProfileEditView: View {
    @Binding var parentReload: Bool
    @ObservedObject var profile: ConfigProfile

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var isLoading = true
    @State private var checkName: Bool = false
    @FocusState private var nameFocus: Bool
    @State private var isChanged: Bool = false

    @State private var errorPresented: Bool = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            HStack {
                if checkName {
                    Text("Name").bold().foregroundColor(.red)
                } else {
                    Text("Name").bold()
                }
                Spacer()
                Spacer()
                TextField("Required", text: $profile.name)
                    .multilineTextAlignment(.trailing)
                    .focused($nameFocus)
                    .onChange(of: profile.name) { _ in
                        isChanged = true
                    }
            }
            NavigationLink(destination: {
                ProfileEditContentView(profile: profile)
            }, label: {
                Text("Edit Content")
            })
        }
        .alert(isPresented: $errorPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Ok"))
            )
        }
        .navigationBarItems(trailing: Button("Save") {
            Task.detached {
                await saveProfile()
            }
        }
        .disabled(!isChanged))
    }

    private func saveProfile() async {
        do {
            _ = try ProfileManager.shared().update(profile)
            parentReload = true
            await MainActor.run {
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
    }
}
