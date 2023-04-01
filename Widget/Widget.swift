import Intents
import SwiftUI
import WidgetKit

struct DashboardEntry: TimelineEntry {
    var date: Date
}

struct DashboardProvider: TimelineProvider {
    typealias Entry = DashboardEntry

    func placeholder(in _: Context) -> Entry {
        DashboardEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (Entry) -> Void) {
        let entry = DashboardEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entries: [DashboardEntry] = [DashboardEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct DashboardView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        ToggleView()
    }
}

@main
struct DashboardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "org.sagernet.sfi.widget",
            provider: DashboardProvider()
        ) { _ in
            DashboardView()
        }
        .configurationDisplayName("sing-box")
        .supportedFamilies([.systemSmall])
    }
}
