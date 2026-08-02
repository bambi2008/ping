import WidgetKit
import SwiftUI

struct PingWidgetEntry: TimelineEntry {
    let date: Date
    let totalMonthly: String
    let currency: String
    let activeCount: Int
    let upcoming: [BillItem]
}

struct BillItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let daysLeft: Int
}

struct PingProvider: TimelineProvider {
    func placeholder(in context: Context) -> PingWidgetEntry {
        PingWidgetEntry(
            date: Date(),
            totalMonthly: "€42",
            currency: "EUR",
            activeCount: 3,
            upcoming: [
                BillItem(name: "Netflix", amount: "€13.99", daysLeft: 3),
                BillItem(name: "Spotify", amount: "€9.99", daysLeft: 7),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PingWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PingWidgetEntry>) -> Void) {
        let entry = readWidgetData()
        let nextUpdate = Date().addingTimeInterval(3600) // Refresh every hour
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readWidgetData() -> PingWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.bambi2008.ping")
        let raw = defaults?.string(forKey: "widget_data") ?? ""

        var total = "—"
        var currency = "EUR"
        var active = 0
        var upcoming: [BillItem] = []

        if let data = raw.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            total = json["total"] as? String ?? "—"
            currency = json["currency"] as? String ?? "EUR"
            active = json["active"] as? Int ?? 0
            if let upcomingArr = json["upcoming"] as? [[String: String]] {
                for item in upcomingArr {
                    let name = item["name"] ?? "Unknown"
                    let amount = item["amount"] ?? ""
                    let daysLeft = Int(item["daysLeft"] ?? "0") ?? 0
                    upcoming.append(BillItem(name: name, amount: amount, daysLeft: daysLeft))
                }
            }
        }

        return PingWidgetEntry(
            date: Date(),
            totalMonthly: total,
            currency: currency,
            activeCount: active,
            upcoming: upcoming
        )
    }
}

struct PingWidgetEntryView: View {
    var entry: PingWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Ping")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(entry.activeCount) active")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Text(entry.totalMonthly)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("per month")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))

            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.vertical, 4)

            if entry.upcoming.isEmpty {
                Text("No upcoming bills")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            } else {
                ForEach(entry.upcoming.prefix(3)) { bill in
                    HStack(spacing: 6) {
                        Text(bill.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(bill.amount)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(bill.daysLeft)d")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(bill.daysLeft <= 1 ? .red : .orange)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }
        }
        .padding(14)
        .containerBackground(
            LinearGradient(
                colors: [Color(red: 0.42, green: 0.36, blue: 0.91), Color(red: 0.64, green: 0.61, blue: 0.99)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }
}

@main
struct PingWidget: Widget {
    let kind: String = "PingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PingProvider()) { entry in
            PingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ping")
        .description("Monthly subscription spend & upcoming bills.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
