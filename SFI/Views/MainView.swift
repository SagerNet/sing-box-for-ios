import Foundation
import NetworkExtension
import SwiftUI

struct MainView: View {
    enum Page {
        case dashboard, logs, profiles, settings
    }

    @State var currentPage: Page = .dashboard

    var body: some View {
        TabView(selection: $currentPage) {
            DashboardView(currentPage: $currentPage).tag(Page.dashboard).tabItem {
                Label("Dashboard", systemImage: "text.and.command.macwindow")
            }

            LogView(currentPage: $currentPage).tag(Page.logs).tabItem {
                Label("Logs", systemImage: "text.and.command.macwindow")
            }

            ProfileView().tag(Page.profiles).tabItem {
                Label("Profiles", systemImage: "doc.fill")
            }

            SettingsView().tag(Page.settings).tabItem {
                Label("Settings", systemImage: "gear.circle.fill")
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
