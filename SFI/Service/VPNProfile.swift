import Foundation
import NetworkExtension

class VPNProfile: ObservableObject {
    let manager: NEVPNManager
    var connection: NEVPNConnection
    @Published var status: NEVPNStatus

    private var observer: Any?

    init(_ manager: NEVPNManager) {
        self.manager = manager
        connection = manager.connection
        status = manager.connection.status
    }

    deinit {
        unregister()
    }

    func register() {
        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            self.connection = notification.object as! NEVPNConnection
            self.status = self.connection.status
        }
    }

    private func unregister() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func start() async throws {
        if let configuration = manager.protocolConfiguration {
            configuration.includeAllNetworks = SharedPreferences.includeAllNetworks
            configuration.excludeLocalNetworks = SharedPreferences.excludeLocalNetworks
            configuration.enforceRoutes = SharedPreferences.enforceRoutes
            manager.protocolConfiguration = configuration
        }
        manager.isEnabled = true
        try await manager.saveToPreferences()
        try manager.connection.startVPNTunnel()
    }

    func stop() {
        manager.connection.stopVPNTunnel()
    }

    static func load() async throws -> VPNProfile? {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        if managers.isEmpty {
            return nil
        }
        let profile = VPNProfile(managers[0])
        return profile
    }

    static func install() async throws -> VPNProfile {
        let manager = NETunnelProviderManager()
        manager.localizedDescription = "utun interface"
        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.providerBundleIdentifier = "\(FilePath.packageName).extension"
        tunnelProtocol.serverAddress = "sing-box"
        manager.protocolConfiguration = tunnelProtocol
        manager.isEnabled = true
        try await manager.saveToPreferences()
        return VPNProfile(manager)
    }
}
