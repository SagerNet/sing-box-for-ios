import SwiftUI

private struct currentPageKey: EnvironmentKey {
    static let defaultValue: Binding<MainView.Page> = .constant(.dashboard)
}

private struct togglePresentedKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

internal extension EnvironmentValues {
    var currentPage: Binding<MainView.Page> {
        get {
            self[currentPageKey.self]
        }
        set {
            self[currentPageKey.self] = newValue
        }
    }

    var togglePresented: Binding<Bool> {
        get {
            self[togglePresentedKey.self]
        }
        set {
            self[togglePresentedKey.self] = newValue
        }
    }
}
