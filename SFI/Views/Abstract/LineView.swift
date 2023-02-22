import Foundation
import SwiftUI

struct LineView: View {
    let name: String
    let value: String

    static let infoFont = Font.system(.caption, design: .monospaced)

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .font(LineView.infoFont)
                .textSelection(.enabled)
        }
    }
}
