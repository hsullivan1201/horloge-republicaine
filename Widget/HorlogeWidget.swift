import WidgetKit
import SwiftUI

// Widgets are not live views: the system asks for a timeline of snapshots
// and shows each one at its moment. We hand it one entry per decimal minute
// (86.4 s), the same way the system clock widgets do per-minute timelines.

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
        let start = Calendar.current.startOfDay(for: now)
        let decimalMinute = 86.4
        let nextTick = (now.timeIntervalSince(start) / decimalMinute).rounded(.up)

        var entries = [DecimalEntry(date: now)]
        for i in 0..<70 {
            // Nudge past the boundary so the snapshot lands in the new minute.
            let date = start.addingTimeInterval((nextTick + Double(i)) * decimalMinute + 0.1)
            entries.append(DecimalEntry(date: date))
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
            HStack(spacing: 16) {
                DecimalClockFace(dayFraction: dec.dayFraction)
                    .frame(width: 116, height: 116)
                dateBlock(timeSize: 32)
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

            if rep.isComplementary {
                Text(RepublicanData.complementaryDays[rep.day - 1])
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
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
