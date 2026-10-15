import WidgetKit
import SwiftUI

// Widgets are snapshots, not live views. iOS coalesces very frequent entries,
// so the timeline advances every five decimal minutes. That is 7m12s on a
// normal day and automatically scales on 23/25-hour DST transition days.

struct DecimalEntry: TimelineEntry {
    let date: Date
}

struct DecimalProvider: TimelineProvider {
    func placeholder(in context: Context) -> DecimalEntry {
        DecimalEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (DecimalEntry) -> Void) {
        completion(DecimalEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DecimalEntry>) -> Void) {
        let now = Date()
        var cursor = now
        var entries = [DecimalEntry(date: cursor)]

        while entries.count < 72 {
            let calendar = RepublicanCalendar.localGregorianCalendar
            let dayStart = calendar.startOfDay(for: cursor)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let fiveDecimalMinutes = dayEnd.timeIntervalSince(dayStart) / 200
            let elapsed = cursor.timeIntervalSince(dayStart)
            var boundary = floor(elapsed / fiveDecimalMinutes) + 1
            var next = dayStart.addingTimeInterval(boundary * fiveDecimalMinutes + 0.1)

            // Keep the first scheduled refresh at least five conventional
            // minutes away when possible. Midnight remains a useful exception
            // so the displayed Republican date rolls over promptly.
            if entries.count == 1 && next.timeIntervalSince(now) < 300 {
                boundary += 1
                next = dayStart.addingTimeInterval(boundary * fiveDecimalMinutes + 0.1)
            }

            if next >= dayEnd {
                next = dayEnd.addingTimeInterval(0.1)
            }

            entries.append(DecimalEntry(date: next))
            cursor = next
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct DecimalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DecimalEntry

    // No app group, so the widget cannot read the app's language setting.
    // It follows the system language instead.
    private var isFrench: Bool {
        Locale.current.language.languageCode?.identifier == "fr"
    }

    var body: some View {
        let dec = RepublicanCalendar.decimalTime(for: entry.date)

        switch family {
        case .systemMedium:
            GeometryReader { proxy in
                let dialSize = min(proxy.size.height, proxy.size.width * 0.39)
                HStack(spacing: 14) {
                    DecimalClockFace(dayFraction: dec.dayFraction)
                        .frame(width: dialSize, height: dialSize)
                        .accessibilityHidden(true)
                    dateBlock(timeSize: 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        default:
            dateBlock(timeSize: 28)
        }
    }

    private func dateBlock(timeSize: Double) -> some View {
        let rep = RepublicanCalendar.date(from: entry.date)
        let dec = RepublicanCalendar.decimalTime(for: entry.date)

        return VStack(spacing: 3) {
            Text(String(format: "%d:%02d", dec.hours, dec.minutes))
                .font(.system(size: timeSize, weight: .medium, design: .serif).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.8)

            if rep.isComplementary {
                Text(RepublicanData.complementaryDays[rep.day - 1])
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text("\(rep.decadeDayName) \(rep.day) \(RepublicanData.months[rep.month])")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }

            Text("An \(RepublicanCalendar.roman(rep.year))")
                .font(.system(size: 10, design: .serif))
                .foregroundStyle(Theme.gold)

            if let rural = rep.ruralDayName {
                Text(isFrench
                     ? "✿ \(rural)"
                     : "✿ \(RepublicanData.ruralDaysEN[rep.month * 30 + rep.day - 1])")
                    .font(.system(size: 10, design: .serif).italic())
                    .foregroundStyle(Theme.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct RepublicanWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RepublicanClock", provider: DecimalProvider()) { entry in
            DecimalWidgetView(entry: entry)
                .containerBackground(Theme.parchment, for: .widget)
                .widgetURL(URL(string: "horloge-republicaine://clock"))
        }
        .configurationDisplayName("Horloge Républicaine")
        .description("L'heure décimale et le calendrier républicain.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct HorlogeWidgetBundle: WidgetBundle {
    var body: some Widget {
        RepublicanWidget()
    }
}
