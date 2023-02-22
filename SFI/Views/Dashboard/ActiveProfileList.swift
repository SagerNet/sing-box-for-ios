import Libbox
import SwiftUI

struct ActiveProfileList: View {
    @Binding var currentPage: MainView.Page
    @ObservedObject var profile: VPNProfile

    @State var isLoading: Bool = true

    @State var profileList: [ConfigProfile]!
    @State var selectedProfileID: Int64!

    @State var errorPresented: Bool = false
    @State var errorMessage = ""

    var body: some View {
        if isLoading {
            Form {
                ProgressView().onAppear(perform: doReload)
            }
        } else {
            viewBuilder {
                if profileList.isEmpty {
                    Text("Empty profiles").frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    Form {
                        SwitchProfileButton(profile: profile)
                        if profile.status.isConnected {
                            ExtensionStatusView(profile: profile)
                        }
                        Section("Profiles") {
                            Picker(selection: $selectedProfileID) {
                                ForEach(profileList, id: \.id) { profile in
                                    Text(profile.name).tag(profile.id)
                                }
                            } label: {}
                                .pickerStyle(.inline)
                                .onChange(of: selectedProfileID) { newProfileID in
                                    Task {
                                        SharedPreferences.selectedProfileID = newProfileID!
                                        if profile.status.isConnected {
                                            var error: NSError?
                                            LibboxClientServiceReload(FilePath.sharedDirectory.relativePath, &error)
                                            if let error {
                                                errorMessage = error.localizedDescription
                                                errorPresented = true
                                            }
                                        }
                                    }
                                }.disabled(!profile.status.isEnabled)
                        }
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
            .onChange(of: currentPage) { newPage in
                if newPage == MainView.Page.profiles {
                    doReload()
                }
            }
        }
    }

    private func doReload() {
        Task {
            fetchProfiles()
        }
    }

    private func fetchProfiles() {
        defer {
            isLoading = false
        }
        do {
            profileList = try ProfileManager.shared().list()
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
            return
        }
        if profileList.isEmpty {
            return
        }
        selectedProfileID = SharedPreferences.selectedProfileID
        if profileList.filter({ profile in
            profile.id == selectedProfileID
        })
        .isEmpty {
            selectedProfileID = profileList[0].id!
            Task {
                SharedPreferences.selectedProfileID = selectedProfileID
            }
        }
    }
}
