import WidgetKit
import SwiftUI

// Widgets are snapshots, not live views. The main widget's timeline advances
// every five decimal minutes: 7m12s on a normal day, scaling automatically on
// 23/25-hour DST transition days. The big lock screen time steps every
// decimal minute (86.4 s), since a stale minute shows at that size.
// The hour bar in between is a ProgressView(timerInterval:), which the
// system animates live without extra entries.
//
// Each timeline asks for a new one at the end of the decimal hour: about
// ten reloads a day, well inside the budget. The app also asks
// for a reload when the language or appearance changes, but WidgetKit can
// refuse that (the simulator does), so this caps how long a change takes to
// show up at one decimal hour.

struct DecimalEntry: TimelineEntry {
    let date: Date
}

struct DecimalProvider: TimelineProvider {
    var decimalMinutes: Double = 5  // spacing between entries
    var entryCount = 72              // 6 hours at 5, about 3.5 hours at 1

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

        // Entries run on past the horizon (six hours in all) so the clock
        // keeps moving if the system is slow to grant the reload.
        while entries.count < entryCount {
            let dayStart = calendar.startOfDay(for: cursor)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let step = dayEnd.timeIntervalSince(dayStart) / 1000 * decimalMinutes
            let elapsed = cursor.timeIntervalSince(dayStart)
            var boundary = floor(elapsed / step) + 1
            var next = dayStart.addingTimeInterval(boundary * step + 0.1)

            // For the five-minute timeline, keep the first scheduled refresh
            // at least five conventional minutes away when possible. Midnight
            // remains a useful exception so the date rolls over promptly.
            if decimalMinutes >= 5 && entries.count == 1 && next.timeIntervalSince(now) < 300 {
                boundary += 1
                next = dayStart.addingTimeInterval(boundary * step + 0.1)
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
    @Environment(\.widgetRenderingMode) private var renderingMode
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

    private var hourBar: some View {
        HourBar(date: entry.date).tint(Theme.blue)
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
            DecimalClockFace(time: dec, style: .compact, monochrome: renderingMode != .fullColor)
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

// A bar across the current decimal hour. ProgressView(timerInterval:) is
// animated live by the system, between timeline entries.
struct HourBar: View {
    let date: Date

    var body: some View {
        let calendar = RepublicanCalendar.localGregorianCalendar
        let start = calendar.startOfDay(for: date)
        let hour = calendar.date(byAdding: .day, value: 1, to: start)!.timeIntervalSince(start) / 10
        let hourStart = start.addingTimeInterval(Double(RepublicanCalendar.decimalTime(for: date).hours) * hour)

        ProgressView(timerInterval: hourStart...hourStart.addingTimeInterval(hour), countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
    }
}

#if os(iOS)
// The lock screen's wide slot given over to the decimal time, as large as
// it fits, with the hour bar and the date underneath.
struct BigTimeView: View {
    let entry: DecimalEntry

    var body: some View {
        let dec = RepublicanCalendar.decimalTime(for: entry.date)
        let rep = RepublicanCalendar.date(from: entry.date)

        VStack(alignment: .leading, spacing: 1) {
            Text(dec.shortText)
                .font(.didot(54, bold: true))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .widgetAccentable()
                .padding(.vertical, -6)
            HStack(spacing: 6) {
                HourBar(date: entry.date)
                    .frame(width: 34)
                Text(rep.republicanDay.shortTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
        .accessibilityElement(children: .combine)
    }
}

struct BigTimeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RepublicanBigTime",
                            provider: DecimalProvider(decimalMinutes: 1, entryCount: 150)) { entry in
            BigTimeView(entry: entry)
                .widgetURL(URL(string: "horloge-republicaine://clock"))
        }
        .configurationDisplayName("Heure décimale")
        .description("L'heure décimale en grand, pour l'écran verrouillé.")
        .supportedFamilies([.accessoryRectangular])
    }
}
#endif

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
#if os(iOS)
        BigTimeWidget()
#endif
    }
}
