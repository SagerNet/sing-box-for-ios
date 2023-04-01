import SwiftUI

struct ToggleView: View {
    var body: some View {
        Image(systemName: "power.circle.fill")
            .resizable()
            .imageScale(.large)
            .padding(46)
            .widgetURL(URL(string: "sing-box://toggle"))
    }
}
