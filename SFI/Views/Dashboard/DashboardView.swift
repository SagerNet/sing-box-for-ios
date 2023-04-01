import SwiftUI

struct DashboardView: View {
    @Environment(\.currentPage) var currentPage
    @Environment(\.scenePhase) var scenePhase

    @State var isLoading = true
    @State var isInstalled = false
    @State var profile: VPNProfile!

    var body: some View {
        NavigationView {
            viewBuilder {
                if isLoading {
                    ProgressView().onAppear(perform: doReload)
                } else {
                    if !isInstalled {
                        InstallProfileButton(parentIsLoading: $isLoading)
                    } else {
                        ActiveProfileList(profile: profile)
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
        .navigationViewStyle(.stack)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                doReload()
            }
        }
        .onChange(of: currentPage.wrappedValue) { newPage in
            if newPage == MainView.Page.profiles {
                doReload()
            }
        }.onDisappear {
            profile = nil
            isLoading = true
        }
    }

    private func doReload() {
        Task.detached {
            await checkProfile()
        }
    }

    private func checkProfile() async {
        if let vpnProfile = try? await VPNProfile.load() {
            profile = vpnProfile
            isInstalled = true
        } else {
            isInstalled = false
        }
        if let profile {
            profile.register()
        }
        isLoading = false
    }
}
