import SwiftUI

@main
struct Application: App {
    init() {
        Task {
            do {
                try await BackgroundTask.setup()
                NSLog("setup background task success")
            } catch {
                NSLog("setup background task error: \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
