import Libbox
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    var commandServer: LibboxCommandServer!
    var boxService: LibboxBoxService!
    var pprofServer: LibboxPProfServer!

    override func startTunnel(options _: [String: NSObject]?) async throws {
        var error: NSError?
        LibboxRedirectStderr(FilePath.cacheDirectory.appendingPathComponent("stderr.log").relativePath, &error)

        if let error {
            writeMessage("(packet-tunnel) redirect stderr error: \(error.localizedDescription)")
        }

        if !SharedPreferences.disableMemoryLimit {
            LibboxSetMemoryLimit()
        }

        commandServer = LibboxNewCommandServer(FilePath.sharedDirectory.relativePath, serverInterface(self))
        do {
            try commandServer.start()
        } catch {
            NSLog("(packet-tunnel): log server start error: \(error.localizedDescription)")
            return
        }
        commandServer.writeMessage("(packet-tunnel) log server started")

        #if DEBUG
            if SharedPreferences.pprofServerEnabled {
                pprofServer = LibboxNewPProfServer(SharedPreferences.pprofServerPort)
                do {
                    try pprofServer.start()
                } catch {
                    writeMessage("(packet-tunnel) error: start pprof server: \(error.localizedDescription)")
                    return
                }
            }
        #endif

        do {
            try FileManager.default.createDirectory(at: FilePath.workingDirectory, withIntermediateDirectories: true)
        } catch {
            writeMessage("(packet-tunnel) error: create working directory: \(error.localizedDescription)")
            return
        }

        LibboxSetup(FilePath.workingDirectory.relativePath, FilePath.cacheDirectory.relativePath, -1, -1)

        startService()
    }

    private func writeMessage(_ message: String) {
        if let commandServer {
            commandServer.writeMessage(message)
        } else {
            NSLog(message)
        }
    }

    private func startService() {
        let profile: ConfigProfile?
        do {
            profile = try ProfileManager.shared().get(profileID: Int64(SharedPreferences.selectedProfileID))
        } catch {
            writeMessage("(packet-tunnel) error: missing default profile: \(error.localizedDescription)")
            return
        }
        guard let profile else {
            writeMessage("(packet-tunnel) error: missing default profile")
            return
        }
        let configContent: String
        do {
            configContent = try profile.readContent()
        } catch {
            writeMessage("(packet-tunnel) error: read config file: \(error.localizedDescription)")
            return
        }
        var error: NSError?
        let service = LibboxNewService(configContent, PlatformInterface(self, commandServer), &error)
        if let error {
            writeMessage("(packet-tunnel) error: create service: \(error.localizedDescription)")
            return
        }
        guard let service else {
            return
        }

        do {
            try service.start()
        } catch {
            writeMessage("(packet-tunnel) error: start service: \(error.localizedDescription)")
            return
        }
        boxService = service
    }

    private func stopService() {
        if let service = boxService {
            do {
                try service.close()
            } catch {
                writeMessage("(packet-tunnel) error: stop service: \(error.localizedDescription)")
            }
            boxService = nil
        }
    }

    private func reloadService() {
        writeMessage("(packet-tunnel) reloading service")
        reasserting = true
        defer {
            reasserting = false
        }
        stopService()
        startService()
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        writeMessage("(packet-tunnel) stopping, reason: \(reason)")
        stopService()
        if let server = pprofServer {
            do {
                try server.close()
            } catch {
                writeMessage("(packet-tunnel) error: stop pprof server: \(error.localizedDescription)")
            }
            pprofServer = nil
        }
        if let server = commandServer {
            try? server.close()
            commandServer = nil
        }
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        messageData
    }

    override func sleep() async {}

    override func wake() {}

    class serverInterface: NSObject, LibboxCommandServerHandlerProtocol {
        unowned let tunnel: PacketTunnelProvider

        init(_ tunnel: PacketTunnelProvider) {
            self.tunnel = tunnel
            super.init()
        }

        func serviceReload() throws {
            tunnel.reloadService()
        }

        func serviceStop() throws {
            tunnel.stopService()
            tunnel.writeMessage("(packet-tunnel) debug: service stopped")
        }
    }
}
