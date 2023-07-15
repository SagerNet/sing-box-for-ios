import Foundation
import NetworkExtension
import SwiftUI

struct MainView: View {
    @Environment(\.openURL) var openURL

    enum Page {
        case dashboard, logs, profiles, settings
    }

    @State var currentPage: Page = .dashboard
    @State var togglePresented = false

    @State var alertPresented = true

    var body: some View {
        TabView(selection: $currentPage) {
            DashboardView().tag(Page.dashboard).tabItem {
                Label("Dashboard", systemImage: "text.and.command.macwindow")
            }

            LogView().tag(Page.logs).tabItem {
                Label("Logs", systemImage: "doc.text.fill")
            }

            ProfileView().tag(Page.profiles).tabItem {
                Label("Profiles", systemImage: "list.bullet.rectangle.fill")
            }

            SettingsView().tag(Page.settings).tabItem {
                Label("Settings", systemImage: "gear.circle.fill")
            }
        }
        .alert(isPresented: $alertPresented) {
            Alert(
                title: Text("Deprecated"),
                message: Text("This app has been deprecated, please migrate to sing-box β"),

                primaryButton: .default(Text("Ok"), action: {
                    UIApplication.shared.open(URL(string: "http://sing-box.sagernet.org/installation/clients/sfi/")!)
                }),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        .environment(\.currentPage, $currentPage)
        .environment(\.togglePresented, $togglePresented)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
