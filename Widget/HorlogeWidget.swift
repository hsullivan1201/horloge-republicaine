import WidgetKit
import SwiftUI

// Widgets are snapshots, not live views. iOS coalesces very frequent entries,
// so the timeline advances every five decimal minutes. That is 7m12s on a
// normal day and automatically scales on 23/25-hour DST transition days.
// The hour bar in between is a ProgressView(timerInterval:), which the
// system animates live without extra entries.
//
// Each timeline runs to the end of the decimal hour and then asks for a new
// one: about ten reloads a day, well inside the budget. The app also asks
// for a reload when the language or appearance changes, but WidgetKit can
// refuse that (the simulator does), so this caps how long a change takes to
// show up at one decimal hour.

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

        // End of this decimal hour, or the next one if this one is nearly over.
        let calendar = RepublicanCalendar.localGregorianCalendar
        let today = calendar.startOfDay(for: now)
        let decimalHour = calendar.date(byAdding: .day, value: 1, to: today)!.timeIntervalSince(today) / 10
        var horizon = today.addingTimeInterval((floor(now.timeIntervalSince(today) / decimalHour) + 1) * decimalHour)
        if horizon.timeIntervalSince(now) < decimalHour / 5 {
            horizon = horizon.addingTimeInterval(decimalHour)
        }

        while cursor < horizon && entries.count < 72 {
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
        completion(Timeline(entries: entries, policy: .after(horizon)))
    }
}

struct DecimalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var systemScheme
    let entry: DecimalEntry

    // Language and appearance come from the app through the app group. If
    // the group is missing, follow the system.
    private var lang: Language {
        if let raw = AppGroup.defaults.string(forKey: "language"), let lang = Language(rawValue: raw) {
            return lang
        }
        return Locale.current.language.languageCode?.identifier == "fr" ? .fr : .en
    }

    private var scheme: ColorScheme {
        let appearance = Appearance(rawValue: AppGroup.defaults.string(forKey: "appearance") ?? "") ?? .auto
        return appearance.colorScheme ?? systemScheme
    }

    var body: some View {
        switch family {
#if os(iOS)
        case .accessoryCircular:
            circular
                .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryRectangular:
            rectangular
                .containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            inline
                .containerBackground(for: .widget) { Color.clear }
#endif
        case .systemMedium:
            medium
                .environment(\.colorScheme, scheme)
                .containerBackground(for: .widget) { Palette.for(scheme).parchment.color }
        default:
            small
                .environment(\.colorScheme, scheme)
                .containerBackground(for: .widget) { Palette.for(scheme).parchment.color }
        }
    }

    private var rep: RepublicanDate { RepublicanCalendar.date(from: entry.date) }
    private var dec: DecimalTime { RepublicanCalendar.decimalTime(for: entry.date) }

    // The current decimal hour, for the live bar.
    private var hourInterval: ClosedRange<Date> {
        let calendar = RepublicanCalendar.localGregorianCalendar
        let start = calendar.startOfDay(for: entry.date)
        let hour = calendar.date(byAdding: .day, value: 1, to: start)!.timeIntervalSince(start) / 10
        let hourStart = start.addingTimeInterval(Double(dec.hours) * hour)
        return hourStart...hourStart.addingTimeInterval(hour)
    }

    private var hourBar: some View {
        ProgressView(timerInterval: hourInterval, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(Theme.blue)
    }

    private var timeLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            DidotTime(text: dec.shortText, size: 36)
            Text("h")
                .font(.didot(14))
                .foregroundStyle(Theme.gold)
        }
    }

    private var dedicationText: String? {
        if rep.isComplementary {
            return lang == .en ? RepublicanData.complementaryDaysEN[rep.day - 1] : nil
        }
        return lang == .fr ? rep.republicanDay.ruralFR : rep.republicanDay.ruralEN
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            timeLine
            hourBar
                .padding(.top, 6)
            Spacer(minLength: 4)
            Text(rep.republicanDay.title)
                .font(.didot(15))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(rep.yearText.uppercased())
                .font(.system(size: 9, weight: .medium))
                .tracking(1)
                .foregroundStyle(Theme.gold)
                .padding(.top, 2)
            if let dedication = dedicationText {
                Text(dedication)
                    .font(.didot(13, italic: true))
                    .foregroundStyle(Theme.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            DecimalClockFace(time: dec, style: .compact)
                .aspectRatio(1, contentMode: .fit)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                timeLine
                hourBar
                Text(rep.republicanDay.title)
                    .font(.didot(16))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 2)
                Text(rep.yearText.uppercased())
                    .font(.system(size: 9.5, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(Theme.gold)
                if let dedication = dedicationText {
                    Text("✿ \(dedication)")
                        .font(.didot(13, italic: true))
                        .foregroundStyle(Theme.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

#if os(iOS)
    private var circular: some View {
        DecimalClockFace(time: dec, style: .accessory)
            .padding(2)
            .widgetAccentable()
            .accessibilityLabel(dec.shortText)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(dec.shortText)
                    .font(.didot(22, bold: true))
                    .widgetAccentable()
                Text(tr(lang, "décimal", "decimal"))
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.7)
            }
            Text(rep.republicanDay.shortTitle)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
            if let dedication = dedicationText {
                Text("✿ \(dedication)")
                    .font(.system(size: 13))
                    .opacity(0.75)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Text("\(rep.republicanDay.shortTitle) · \(dec.shortText)")
    }
#endif
}

struct RepublicanWidget: Widget {
    private var families: [WidgetFamily] {
#if os(iOS)
        [.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
#else
        [.systemSmall, .systemMedium]
#endif
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RepublicanClock", provider: DecimalProvider()) { entry in
            DecimalWidgetView(entry: entry)
                .widgetURL(URL(string: "horloge-republicaine://clock"))
        }
        .configurationDisplayName("Horloge Républicaine")
        .description("L'heure décimale et le calendrier républicain.")
        .supportedFamilies(families)
    }
}

@main
struct HorlogeWidgetBundle: WidgetBundle {
    var body: some Widget {
        RepublicanWidget()
    }
}
