import Foundation
import NetworkExtension
import SwiftUI

struct MainView: View {
    enum Page {
        case dashboard, logs, profiles, settings
    }

    @State var currentPage: Page = .dashboard
    @State var togglePresented = false

    var body: some View {
        TabView(selection: $currentPage) {
            DashboardView().tag(Page.dashboard).tabItem {
                Label("Dashboard", systemImage: "text.and.command.macwindow")
            }

            LogView().tag(Page.logs).tabItem {
                Label("Logs", systemImage: "text.and.command.macwindow")
            }

            ProfileView().tag(Page.profiles).tabItem {
                Label("Profiles", systemImage: "doc.fill")
            }

            SettingsView().tag(Page.settings).tabItem {
                Label("Settings", systemImage: "gear.circle.fill")
            }
        }
        .environment(\.currentPage, $currentPage)
        .environment(\.togglePresented, $togglePresented)
        .onOpenURL(perform: openURL)
    }

    private func openURL(url: URL) {
        if url.scheme != "sing-box" {
            return
        }
        switch url.host {
        case "toggle":
            currentPage = .dashboard
            togglePresented = true
        default: break
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
