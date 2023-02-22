import Foundation
import SwiftUI

func viewBuilder(@ViewBuilder _ builder: () -> some View) -> some View {
    builder()
}
