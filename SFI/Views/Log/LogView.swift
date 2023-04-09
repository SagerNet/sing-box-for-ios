import Libbox
import SwiftUI

struct LogView: View {
    @Environment(\.currentPage) var currentPage

    @State private var isLoading: Bool = true
    @State private var isConnected: Bool = false
    @State private var logList: [String] = []
    @State private var commandClient: LibboxCommandClient!

    private let logFont = Font.system(.caption, design: .monospaced)

    var body: some View {
        NavigationView {
            viewBuilder {
                if isLoading {
                    ProgressView().onAppear(perform: doReload)
                } else {
                    viewBuilder {
                        if logList.isEmpty, !isConnected {
                            Text("Service not started")
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    alignment: .center
                                )
                        } else {
                            Form {
                                List {
                                    ForEach(logList, id: \.self) { it in
                                        Text(it).font(logFont)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: currentPage.wrappedValue) { newPage in
                        if newPage == MainView.Page.logs, !isConnected {
                            doReload()
                        }
                    }
                }
            }
            .navigationTitle("Logs")
        }
        .navigationViewStyle(.stack)
        .onDisappear {
            try? commandClient?.disconnect()
            commandClient = nil
            isLoading = true
        }
    }

    private func doReload() {
        Task.detached {
            connect()
        }
    }

    private func connect() {
        try? commandClient?.disconnect()
        let clientOptions = LibboxCommandClientOptions()
        clientOptions.command = LibboxCommandLog
        commandClient = LibboxNewCommandClient(FilePath.sharedDirectory.relativePath, logHandler(self), clientOptions)
        try? commandClient.connect()
        isLoading = false
    }

    class logHandler: NSObject, LibboxCommandClientHandlerProtocol {
        let logView: LogView

        init(_ logView: LogView) {
            self.logView = logView
        }

        func connected() {
            logView.logList.removeAll()
            logView.isConnected = true
        }

        func disconnected(_ message: String?) {
            if let message {
                logView.logList.insert("(log client closed) \(message)", at: 0)
            } else {
                logView.logList.insert("(log client closed)", at: 0)
            }
            logView.isConnected = false
        }

        func writeLog(_ message: String?) {
            guard let message else {
                return
            }
            if logView.logList.count > 100 {
                logView.logList.removeLast()
            }
            logView.logList.insert(message, at: 0)
        }

        func writeStatus(_: LibboxStatusMessage?) {}
    }
}
