import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ServiceLogView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var isLoading = true
    @State private var content = ""
    @State private var fileExporterPresented = false

    private let logFont = Font.system(.caption, design: .monospaced)

    var body: some View {
        viewBuilder {
            if isLoading {
                ProgressView().onAppear {
                    Task.detached {
                        loadContent()
                    }
                }
            } else {
                if content.isEmpty {
                    Text("Empty content")
                } else {
                    ScrollView {
                        Text(content).font(logFont)
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            Button("Export") {
                fileExporterPresented = true
            }
            .disabled(content.isEmpty)
        }
        .fileExporter(
            isPresented: $fileExporterPresented,
            document: LogDocument(content),
            contentType: .log,
            defaultFilename: "service.log",
            onCompletion: { _ in }
        )
        .navigationTitle("Service Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadContent() {
        do {
            content = try String(contentsOf: FilePath.cacheDirectory.appendingPathComponent("stderr.log"))
        } catch {}
        if content.isEmpty {
            do {
                content = try String(contentsOf: FilePath.cacheDirectory.appendingPathComponent("stderr.log.old"))
            } catch {}
        }
        isLoading = false
    }
}

struct LogDocument: FileDocument {
    static var readableContentTypes = [UTType.log]

    let content: String

    init(_ content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            content = String(decoding: data, as: UTF8.self)
        } else {
            content = ""
        }
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(content.utf8))
    }
}
