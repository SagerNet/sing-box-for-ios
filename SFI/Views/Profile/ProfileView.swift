import SwiftUI

struct ProfileView: View {
    @State var isLoading = true

    @State var errorPresented: Bool = false
    @State var errorMessage = ""

    @State var profileList: [ConfigProfile] = []
    @State var editMode = EditMode.inactive

    var body: some View {
        NavigationView {
            Form {
                if isLoading {
                    ProgressView().onAppear(perform: doReload)
                } else {
                    NavigationLink {
                        NewProfileView(isLoading: $isLoading).navigationTitle("New Profile")
                    } label: {
                        Text("New Profile").foregroundColor(.accentColor)
                    }.disabled(editMode.isEditing)
                    List {
                        ForEach(profileList, id: \.id) { profile in
                            viewBuilder {
                                if editMode.isEditing == true {
                                    Text(profile.name)
                                } else {
                                    NavigationLink {
                                        ProfileEditView(parentReload: $isLoading, profile: profile).navigationTitle("Edit Profile")
                                    } label: {
                                        Text(profile.name)
                                    }
                                }
                            }
                        }
                        .onMove(perform: moveProfile)
                        .onDelete(perform: deleteProfile)
                    }
                }
            }
            .navigationTitle("Profiles")
            .navigationBarItems(trailing: EditButton())
            .environment(\.editMode, $editMode)
        }
        .navigationViewStyle(.stack)
        .alert(isPresented: $errorPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Ok"))
            )
        }
    }

    private func doReload() {
        Task.detached {
            fetchProfiles()
        }
    }

    private func fetchProfiles() {
        do {
            profileList = try ProfileManager.shared().list()
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
        isLoading = false
    }

    func deleteProfile(_ profile: ConfigProfile) {
        Task.detached {
            do {
                _ = try ProfileManager.shared().delete(profile)
                isLoading = true
            } catch {
                errorMessage = error.localizedDescription
                errorPresented = true
            }
        }
    }

    func moveProfile(from source: IndexSet, to destination: Int) {
        profileList.move(fromOffsets: source, toOffset: destination)
        for (index, profile) in profileList.enumerated() {
            profile.order = UInt32(index)
        }
        do {
            try ProfileManager.shared().update(profileList)
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
    }

    func deleteProfile(where profileIndex: IndexSet) {
        let profileToDelete = profileIndex.map { index -> ConfigProfile in
            profileList[index]
        }
        profileList.remove(atOffsets: profileIndex)
        Task.detached {
            do {
                _ = try ProfileManager.shared().delete(profileToDelete)
            } catch {
                errorMessage = error.localizedDescription
                errorPresented = true
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
