import Foundation
import Libbox
import SwiftUI

struct ExtensionStatusView: View {
    @ObservedObject var profile: VPNProfile

    @State var isLoading: Bool = true
    @State var commandClient: LibboxCommandClient!
    @State var message: LibboxStatusMessage!

    @State var connectTask: Task<Void, Error>?
    let infoFont = Font.system(.caption, design: .monospaced)

    var body: some View {
        Section("Status") {
            if isLoading {
                StatusContentView().onAppear(perform: doReload)
            } else {
                StatusContentView(message)
            }
        }
        .onDisappear {
            connectTask?.cancel()
            if let commandClient {
                try? commandClient.disconnect()
            }
            commandClient = nil
            isLoading = true
        }
    }

    private func doReload() {
        connectTask?.cancel()
        connectTask = Task.detached {
            await connect()
        }
    }

    private func connect() async {
        defer {
            isLoading = false
        }
        let clientOptions = LibboxCommandClientOptions()
        clientOptions.command = LibboxCommandStatus
        clientOptions.statusInterval = Int64(2 * NSEC_PER_SEC)
        let client = LibboxNewCommandClient(FilePath.sharedDirectory.relativePath, statusHandler(self), clientOptions)!

        do {
            for _ in 0 ..< 10 {
                try await Task.sleep(nanoseconds: UInt64(100 * Double(NSEC_PER_MSEC)))
                try Task.checkCancellation()
                let isConnected: Bool
                do {
                    try client.connect()
                    isConnected = true
                } catch {
                    isConnected = false
                }
                try Task.checkCancellation()
                if isConnected {
                    commandClient = client
                    return
                }
            }
        } catch {
            try? client.disconnect()
        }
    }

    class statusHandler: NSObject, LibboxCommandClientHandlerProtocol {
        let statusView: ExtensionStatusView

        init(_ statusView: ExtensionStatusView) {
            self.statusView = statusView
        }

        func connected() {}

        func disconnected(_: String?) {}

        func writeLog(_: String?) {}

        func writeStatus(_ message: LibboxStatusMessage?) {
            statusView.message = message
        }

        func writeGroups(_: LibboxOutboundGroupIteratorProtocol?) {}
    }
}

struct StatusContentView: View {
    unowned let message: LibboxStatusMessage?

    @State var errorPresented: Bool = false
    @State var errorMessage = ""

    init(_ message: LibboxStatusMessage? = nil) {
        self.message = message
    }

    var body: some View {
        viewBuilder {
            if let message {
                LineView(name: "Memory", value: LibboxFormatBytes(message.memory))
                LineView(name: "Goroutines", value: "\(message.goroutines)")
                LineView(name: "Connections", value: "\(message.connections)").contextMenu {
                    Button("Close", role: .destructive) {
                        Task.detached {
                            closeConnections()
                        }
                    }
                }
            } else {
                LineView(name: "Memory", value: "Loading...")
                LineView(name: "Goroutines", value: "Loading...")
                LineView(name: "Connections", value: "Loading...")
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

    private func closeConnections() {
        do {
            try LibboxNewStandaloneCommandClient(FilePath.sharedDirectory.relativePath)?.closeConnections()
        } catch {
            errorMessage = error.localizedDescription
            errorPresented = true
        }
    }
}
