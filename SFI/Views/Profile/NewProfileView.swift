import Foundation
import SwiftUI

struct NewProfileView: View {
    @Binding var isLoading: Bool
    @State var isSaving = false

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var name: String = ""

    @State var type: ConfigProfile.ProfileType = .local

    @State var fileImport: Bool = false
    @State var fileURL: URL!

    @State var checkName = false
    @FocusState var nameFocus: Bool

    @State var filePath = ""
    @State var checkPath = false
    @FocusState var pathFocus: Bool

    @State var pickerPresented = false

    @State var errorPresented = false
    @State var errorMessage = ""

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
                TextField("Required", text: $name)
                    .multilineTextAlignment(.trailing)
                    .onSubmit {
                        if !name.isEmpty {
                            checkName = false
                        }
                    }
                    .focused($nameFocus)
            }
            Picker(selection: $type) {
                Text("Local").tag(ConfigProfile.ProfileType.local)
                Text("iCloud").tag(ConfigProfile.ProfileType.icloud)
//                Text("Remote").tag(ConfigProfile.ProfileType.remote)
            } label: {
                Text("Type").bold()
            }
            if type == .local {
                Picker(selection: $fileImport) {
                    Text("Create New").tag(false)
                    Text("Import").tag(true)
                } label: {
                    Text("File").bold()
                }
                if fileImport {
                    HStack {
                        Text("File Path").bold()
                        Spacer()
                        Spacer()
                        if let fileURL {
                            Button(fileURL.fileName) {
                                pickerPresented = true
                            }
                        } else {
                            Button("Choose") {
                                pickerPresented = true
                            }
                        }
                    }
                    .fileImporter(
                        isPresented: $pickerPresented,
                        allowedContentTypes: [.json],
                        allowsMultipleSelection: false
                    ) { result in
                        do {
                            let urls = try result.get()
                            if !urls.isEmpty {
                                fileURL = urls[0]
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            errorPresented = true
                            return
                        }
                    }
                }
            } else if type == .icloud {
                HStack {
                    if checkPath {
                        Text("Path").bold().foregroundColor(.red)
                    } else {
                        Text("Path").bold()
                    }
                    Spacer()
                    Spacer()
                    TextField("Required", text: $filePath)
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            if !filePath.isEmpty {
                                checkPath = false
                            }
                        }
                        .focused($pathFocus)
                }
            }
            Section {
                if !isSaving {
                    Button("Create") {
                        Task.detached {
                            await createProfile()
                        }
                    }
                } else {
                    ProgressView()
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

    private func createProfile() async {
        if name.isEmpty {
            checkName = true
            nameFocus = true
            return
        }
        if type == .icloud {
            if filePath.isEmpty {
                checkPath = true
                pathFocus = true
                return
            }
        }
        isSaving = true
        defer {
            isSaving = false
        }
        do {
            let profileManager = try ProfileManager.shared()
            let nextProfileID = try profileManager.nextID()

            var savePath = ""

            if type == .local {
                let profileConfigDirectory = FilePath.sharedDirectory.appendingPathComponent("configs", isDirectory: true)
                try FileManager.default.createDirectory(at: profileConfigDirectory, withIntermediateDirectories: true)
                let profileConfig = profileConfigDirectory.appendingPathComponent("config_\(nextProfileID).json")
                if fileImport {
                    guard let fileURL else {
                        errorMessage = "Missing file"
                        errorPresented = true
                        return
                    }
                    if !fileURL.startAccessingSecurityScopedResource() {
                        errorMessage = "Missing access to selected file"
                        errorPresented = true
                        return
                    }
                    defer {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                    try String(contentsOf: fileURL).write(to: profileConfig, atomically: true, encoding: .utf8)
                } else {
                    try "{}".write(to: profileConfig, atomically: true, encoding: .utf8)
                }
                savePath = profileConfig.relativePath
            } else if type == .icloud {
                if !FileManager.default.fileExists(atPath: FilePath.iCloudDirectory.path) {
                    try FileManager.default.createDirectory(at: FilePath.iCloudDirectory, withIntermediateDirectories: true)
                }
                let saveURL = FilePath.iCloudDirectory.appendingPathComponent(filePath, isDirectory: false)
                saveURL.startAccessingSecurityScopedResource()
                defer {
                    saveURL.stopAccessingSecurityScopedResource()
                }
                let exists: Bool
                do {
                    try String(contentsOf: saveURL)
                    exists = true
                } catch {
                    exists = false
                }
                if !exists {
                    try "{}".write(to: saveURL, atomically: true, encoding: .utf8)
                }
                savePath = filePath
            }
            try ProfileManager.shared().create(ConfigProfile(name: name, type: type, path: savePath))
            isLoading = true
            await MainActor.run {
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
            return
        }
    }
}
