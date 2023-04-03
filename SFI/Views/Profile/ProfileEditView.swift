import Foundation
import Libbox
import SwiftUI

struct ProfileEditView: View {
    @Binding var parentReload: Bool
    @ObservedObject var profile: ConfigProfile

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var isLoading = false

    @State private var checkName = false
    @FocusState private var nameFocus: Bool

    @State var checkPath = false
    @FocusState var pathFocus: Bool

    @State private var isChanged = false

    @State private var errorPresented = false
    @State private var errorMessage = ""

    @State private var checkPresented = false
    @State private var checkTitle = ""
    @State private var checkMessage = ""

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
            Picker(selection: $profile.type) {
                Text("Local").tag(ConfigProfile.ProfileType.local)
                Text("iCloud").tag(ConfigProfile.ProfileType.icloud)
                Text("Remote").tag(ConfigProfile.ProfileType.remote)
            } label: {
                Text("Type").bold()
            }
            .disabled(true)
            if profile.type == .icloud {
                HStack {
                    if checkPath {
                        Text("Path").bold().foregroundColor(.red)
                    } else {
                        Text("Path").bold()
                    }
                    Spacer()
                    Spacer()
                    TextField("Required", text: $profile.path)
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            if !profile.path.isEmpty {
                                checkPath = false
                            }
                            isChanged = true
                        }
                        .focused($pathFocus)
                }
            } else if profile.type == .remote {
                HStack {
                    if checkPath {
                        Text("URL").bold().foregroundColor(.red)
                    } else {
                        Text("URL").bold()
                    }
                    Spacer()
                    Spacer()
                    TextField("Required", text: ($profile.remoteURL).unwrapped(""))
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            if !profile.path.isEmpty {
                                checkPath = false
                            }
                            isChanged = true
                        }
                        .focused($pathFocus)
                }
                HStack {
                    Text("Auto Update").bold()
                    Spacer()
                    Spacer()
                    Toggle("", isOn: $profile.autoUpdate)
                        .onChange(of: profile.autoUpdate) { _ in
                            isChanged = true
                        }
                }
            }
            if profile.type == .remote {
                Section("Status") {
                    LineView(name: "Last Updated", value: formatDate(profile.lastUpdated))
                }
            }
            Section("Action") {
                if isLoading {
                    ProgressView()
                } else if profile.type == .local {
                    NavigationLink(destination: {
                        ProfileEditContentView(profile: profile)
                    }, label: {
                        Text("Edit Content").foregroundColor(.accentColor)
                    })
                } else if profile.type == .remote {
                    Button("Update") {
                        isLoading = true
                        Task.detached {
                            await updateProfile()
                        }
                    }
                    .disabled(isChanged)
                }
                Button("Check") {
                    Task.detached {
                        await checkProfile()
                    }
                }
                .disabled(isLoading)
                .alert(isPresented: $checkPresented) {
                    Alert(
                        title: Text(checkTitle),
                        message: Text(checkMessage),
                        dismissButton: .default(Text("Ok"))
                    )
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
        .navigationBarItems(trailing: Button("Save") {
            Task.detached {
                await saveProfile()
            }
        }
        .disabled(!isChanged))
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else {
            return "unknown"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
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

    private func checkProfile() async {
        do {
            let profileContent = try profile.readContent()
            var error: NSError?
            LibboxCheckConfig(profileContent, &error)
            if let error {
                checkTitle = "Failed"
                checkMessage = error.localizedDescription
            } else {
                checkTitle = "Success"
                checkMessage = ""
            }
            checkPresented = true
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
    }

    private func updateProfile() async {
        defer {
            isLoading = false
        }
        do {
            let profileManager = try ProfileManager.shared()
            try profileManager.updateRemoteProfile(profile)
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
    }
}
