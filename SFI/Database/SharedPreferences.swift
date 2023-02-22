import Defaults
import Foundation

class SharedPreferences {
    static var sharedDefaults = UserDefaults(suiteName: FilePath.groupName) ?? UserDefaults.standard

    static var selectedProfileID: Int64 {
        get {
            sharedDefaults[.selectedProfileID]
        }
        set {
            sharedDefaults[.selectedProfileID] = newValue
        }
    }

    static var includeAllNetworks: Bool {
        get {
            sharedDefaults[.includeAllNetworks]
        }
        set {
            sharedDefaults[.includeAllNetworks] = newValue
        }
    }

    static var excludeLocalNetworks: Bool {
        get {
            sharedDefaults[.excludeLocalNetworks]
        }
        set {
            sharedDefaults[.excludeLocalNetworks] = newValue
        }
    }

    static var enforceRoutes: Bool {
        get {
            sharedDefaults[.enforceRoutes]
        }
        set {
            sharedDefaults[.enforceRoutes] = newValue
        }
    }

    static var disableMemoryLimit: Bool {
        get {
            sharedDefaults[.disableMemoryLimit]
        }
        set {
            sharedDefaults[.disableMemoryLimit] = newValue
        }
    }

    static var pprofServerEnabled: Bool {
        get {
            sharedDefaults[.pprofServerEnabled]
        }
        set {
            sharedDefaults[.pprofServerEnabled] = newValue
        }
    }

    static var pprofServerPort: Int {
        get {
            sharedDefaults[.pprofServerPort]
        }
        set {
            sharedDefaults[.pprofServerPort] = newValue
        }
    }
}

extension Defaults.Keys {
    static let selectedProfileID = Key<Int64>("selected_profile_id", default: 0, suite: SharedPreferences.sharedDefaults)

    static let includeAllNetworks = Key<Bool>("include_all_networks", default: false, suite: SharedPreferences.sharedDefaults)

    static let excludeLocalNetworks = Key<Bool>("exclude_local_networks", default: true, suite: SharedPreferences.sharedDefaults)

    static let enforceRoutes = Key<Bool>("enforce_routes", default: false, suite: SharedPreferences.sharedDefaults)

    static let disableMemoryLimit = Key<Bool>("disable_memory_limit", default: false, suite: SharedPreferences.sharedDefaults)

    static let pprofServerEnabled = Key<Bool>("pprof_server_enabled", default: false, suite: SharedPreferences.sharedDefaults)

    static let pprofServerPort = Key<Int>("pprof_server_port", default: 8080, suite: SharedPreferences.sharedDefaults)
}
