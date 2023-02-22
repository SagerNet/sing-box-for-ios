import Foundation
import SwiftUI

struct NewProfileView: View {
    @Binding var isLoading: Bool

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var name: String = ""
    @State var fileImport: Bool = false
    @State var fileURL: URL!

    @State var checkName: Bool = false
    @FocusState var nameFocus: Bool
    @State var pickerPresented: Bool = false

    @State var errorPresented: Bool = false
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
                    }.focused($nameFocus)
            }
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
            }
            Section {
                Button("Create") {
                    Task {
                        createProfile()
                    }
                }
            }
        }.fileImporter(
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
        .alert(isPresented: $errorPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Ok"))
            )
        }
    }

    func createProfile() {
        if name.isEmpty {
            checkName = true
            nameFocus = true
            return
        }
        do {
            let profileManager = try ProfileManager.shared()
            let nextProfileID = try profileManager.nextID()
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
            try ProfileManager.shared().create(ConfigProfile(name: name, path: profileConfig.relativePath))
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
            return
        }
        isLoading = true
        presentationMode.wrappedValue.dismiss()
    }
}
