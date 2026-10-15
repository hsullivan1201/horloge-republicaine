import SwiftUI
import AppKit
import WidgetKit

@main
struct HorlogeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("Horloge Républicaine", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)

        Window("Almanach Républicain", id: "almanach") {
            AlmanachView()
        }
        .defaultSize(width: 760, height: 580)

        MenuBarExtra {
            MenuBarPopover()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppGroup.migrate()
        AppGroup.defaults.register(defaults: [
            "language": Language.fr.rawValue,
            "appearance": Appearance.auto.rawValue,
            "menuBarStyle": MenuBarStyle.time.rawValue,
        ])
        Settings.applyAppearance()
        NSApp.activate(ignoringOtherApps: true)
        ChimeController.shared.start()
    }
}

// Side effects of changing a setting: the Mac app sets its appearance
// app-wide (which also reaches the menu bar panel, where
// preferredColorScheme is ignored), and the widget re-reads both.
enum Settings {
    static func applyAppearance() {
        let raw = AppGroup.defaults.string(forKey: "appearance") ?? ""
        switch Appearance(rawValue: raw) ?? .auto {
        case .auto: NSApp.appearance = nil
        case .jour: NSApp.appearance = NSAppearance(named: .aqua)
        case .nuit: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    static func changed() {
        applyAppearance()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// A binding that runs Settings.changed() after each write.
func settingBinding(_ value: Binding<String>) -> Binding<String> {
    Binding(get: { value.wrappedValue }, set: {
        value.wrappedValue = $0
        Settings.changed()
    })
}

struct RevolutionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, design: .serif))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(configuration.isPressed ? Theme.gold.opacity(0.35) : Theme.cell)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Theme.gold.opacity(0.7), lineWidth: 1)
            )
    }
}

private let oldStyleFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f
}()

private func fullDateFormatter(_ lang: Language) -> DateFormatter {
    lang == .fr ? fullFR : fullEN
}

private let fullFR: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "fr_FR")
    f.dateStyle = .full
    return f
}()

private let fullEN: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.dateStyle = .full
    return f
}()

// Shown when clicking a day: the Republican date and its old-style
// equivalent for the current Republican year.
struct DayInfoPopover: View {
    let lang: Language
    let rep: RepublicanDate  // today, for year context
    let month: Int           // 0-11, or 12 for the complementary days
    let day: Int

    var body: some View {
        let target = RepublicanDay(month: month, day: day)

        VStack(alignment: .leading, spacing: 6) {
            Text("\(target.title) · \(rep.yearText)")
                .font(.didot(17))
                .foregroundStyle(Theme.ink)
            if let dedication = target.dedication(lang) {
                Text("✿ \(dedication)")
                    .font(.system(size: 12, design: .serif).italic())
                    .foregroundStyle(Theme.red)
            }

            Divider()

            Text(tr(lang, "ancien style : ", "old style: ")
                 + fullDateFormatter(lang).string(from: target.gregorianDate(yearStart: rep.yearStart)))
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Theme.faded)
        }
        .padding(14)
        .background(Theme.parchment)
    }
}

// MARK: - Menu bar

enum MenuBarStyle: String, CaseIterable {
    case time, dial, date

    func label(_ lang: Language) -> String {
        switch self {
        case .time: return tr(lang, "Heure", "Time")
        case .dial: return tr(lang, "Cadran", "Dial")
        case .date: return "Date"
        }
    }
}

struct MenuBarLabel: View {
    @AppStorage("menuBarStyle", store: AppGroup.defaults) private var styleRaw = MenuBarStyle.time.rawValue

    var body: some View {
        switch MenuBarStyle(rawValue: styleRaw) ?? .time {
        case .time: SecondsMenuBarLabel()
        case .dial: MinutesMenuBarLabel(showDial: true)
        case .date: MinutesMenuBarLabel(showDial: false)
        }
    }
}

private struct SecondsMenuBarLabel: View {
    @StateObject private var ticker = DecimalTicker()

    var body: some View {
        Text(RepublicanCalendar.decimalTime(for: ticker.now).text)
            .monospacedDigit()
    }
}

// The dial and date styles drop the seconds, so they only wake up once per
// decimal minute.
private struct MinutesMenuBarLabel: View {
    let showDial: Bool
    @StateObject private var ticker = DecimalTicker(every: 100)

    var body: some View {
        let dec = RepublicanCalendar.decimalTime(for: ticker.now)
        if showDial {
            HStack(spacing: 4) {
                Image(nsImage: Self.dialImage(dec))
                Text(dec.shortText).monospacedDigit()
            }
        } else {
            let rep = RepublicanCalendar.date(from: ticker.now)
            let date = rep.isComplementary
                ? RepublicanData.complementaryDays[rep.day - 1]
                : "\(rep.day) \(RepublicanData.months[rep.month].prefix(4))."
            Text("\(date) · \(dec.shortText)").monospacedDigit()
        }
    }

    // A tiny 10-hour face drawn as a template image, so the menu bar tints
    // it for light, dark and highlighted states.
    static func dialImage(_ time: DecimalTime) -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { rect in
            NSColor.black.set()
            let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            ring.lineWidth = 1.3
            ring.stroke()

            let center = NSPoint(x: rect.midX, y: rect.midY)
            func hand(_ turns: Double, length: Double, width: Double) {
                let a = turns * 2 * .pi
                let path = NSBezierPath()
                path.move(to: center)
                path.line(to: NSPoint(x: center.x + sin(a) * length, y: center.y + cos(a) * length))
                path.lineWidth = width
                path.lineCapStyle = .round
                path.stroke()
            }
            hand(time.dayFraction, length: 3.8, width: 1.9)
            hand((time.dayFraction * 10).truncatingRemainder(dividingBy: 1), length: 5.6, width: 1.1)
            return true
        }
        image.isTemplate = true
        return image
    }
}

struct MenuBarPopover: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage("language", store: AppGroup.defaults) private var languageRaw = Language.fr.rawValue
    @AppStorage("chime", store: AppGroup.defaults) private var chime = true
    @AppStorage("menuBarStyle", store: AppGroup.defaults) private var menuBarStyle = MenuBarStyle.time.rawValue
    @StateObject private var ticker = DecimalTicker()

    var body: some View {
        let lang = Language(rawValue: languageRaw) ?? .fr
        let rep = RepublicanCalendar.date(from: ticker.now)
        let dec = RepublicanCalendar.decimalTime(for: ticker.now)

        VStack(spacing: 10) {
            DidotTime(text: dec.text, size: 34)

            VStack(spacing: 3) {
                Text(rep.republicanDay.title)
                    .font(.didot(18))
                    .foregroundStyle(Theme.ink)
                Text(rep.yearText.uppercased())
                    .font(.didot(11))
                    .tracking(1.2)
                    .foregroundStyle(Theme.gold)
                if let dedication = rep.republicanDay.dedication(lang) {
                    Text("✿ \(dedication)")
                        .font(.system(size: 11, design: .serif).italic())
                        .foregroundStyle(Theme.red)
                }
            }

            Divider()

            HStack(spacing: 10) {
                Button(tr(lang, "Horloge", "Clock")) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
                Button(tr(lang, "Almanach", "Almanac")) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "almanach")
                }
                Button(tr(lang, "Quitter", "Quit")) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(RevolutionButtonStyle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(tr(lang, "barre de menus", "menu bar"))
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(Theme.faded)
                    Picker("", selection: $menuBarStyle) {
                        ForEach(MenuBarStyle.allCases, id: \.self) { style in
                            Text(style.label(lang)).tag(style.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                HStack(spacing: 6) {
                    Toggle(isOn: $chime) {
                        Text(tr(lang, "carillon de l'heure décimale", "decimal hour chime"))
                            .font(.system(size: 11, design: .serif))
                            .foregroundStyle(Theme.faded)
                    }
                    .toggleStyle(.checkbox)
                    Button {
                        ChimeController.shared.preview()
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.blue)
                    }
                    .buttonStyle(.plain)
                    .help(tr(lang, "écouter", "listen"))
                }
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(Theme.parchment)
    }
}

// MARK: - Main window

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage("language", store: AppGroup.defaults) private var languageRaw = Language.fr.rawValue
    @AppStorage("appearance", store: AppGroup.defaults) private var appearanceRaw = Appearance.auto.rawValue
    @State private var browsedMonth: Int? = nil  // nil = follow today
    // The date side only needs to notice midnight, so it re-renders once per
    // decimal minute. The clock column ticks on its own.
    @StateObject private var ticker = DecimalTicker(every: 100)

    var body: some View {
        let lang = Language(rawValue: languageRaw) ?? .fr
        let rep = RepublicanCalendar.date(from: ticker.now)

        VStack(spacing: 0) {
            TricolorBar()

            HStack(alignment: .top, spacing: 34) {
                ClockColumn(lang: lang)
                    .frame(width: 250)

                VStack(alignment: .leading, spacing: 16) {
                    DateHeading(rep: rep, lang: lang)
                    CalendarPanel(rep: rep, lang: lang, browsedMonth: $browsedMonth)
                }
                .frame(width: 424)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 18)

            HStack(spacing: 12) {
                Picker("", selection: settingBinding($languageRaw)) {
                    Text("FR").tag(Language.fr.rawValue)
                    Text("EN").tag(Language.en.rawValue)
                }
                .pickerStyle(.segmented)
                .frame(width: 84)
                .labelsHidden()

                Picker("", selection: settingBinding($appearanceRaw)) {
                    ForEach(Appearance.allCases, id: \.self) { appearance in
                        Text(appearance.label(lang)).tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
                .labelsHidden()

                Spacer()

                Button {
                    openWindow(id: "almanach")
                } label: {
                    Label(tr(lang, "Almanach", "Almanac"), systemImage: "book.closed")
                        .font(.system(size: 13, design: .serif))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.blue)
                .help(tr(lang, "Tout le savoir du calendrier républicain",
                         "Everything about the Republican calendar"))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 18)

            TricolorBar()
        }
        .background(Theme.parchment)
        .fixedSize()
    }
}

// The only part of the window that ticks every decimal second.
private struct ClockColumn: View {
    let lang: Language
    @StateObject private var ticker = DecimalTicker()

    var body: some View {
        let dec = RepublicanCalendar.decimalTime(for: ticker.now)

        VStack(spacing: 12) {
            Text("LIBERTÉ · ÉGALITÉ · FRATERNITÉ")
                .font(.didot(10.5))
                .tracking(2.6)
                .foregroundStyle(Theme.gold)
                .fixedSize()

            DecimalClockFace(time: dec)
                .frame(width: 236, height: 236)
                .accessibilityLabel(tr(lang, "Cadran décimal", "Decimal dial"))

            DidotTime(text: dec.text, size: 46)

            Text(tr(lang, "heure ancienne ", "old style ") + oldStyleFormatter.string(from: ticker.now))
                .font(.system(size: 11, design: .serif).monospacedDigit())
                .foregroundStyle(Theme.faded)
        }
    }
}

private struct DateHeading: View {
    let rep: RepublicanDate
    let lang: Language

    var body: some View {
        let today = rep.republicanDay

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(today.title)
                    .font(.didot(31))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(rep.yearText.uppercased())
                    .font(.didot(15))
                    .tracking(1.4)
                    .foregroundStyle(Theme.gold)
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if today.isComplementary {
                    Text(tr(lang, "SANS-CULOTTIDE", "SANS-CULOTTIDE"))
                        .font(.system(size: 9.5, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.gold)
                    Text(lang == .fr
                         ? "jour complémentaire \(today.day)"
                         : RepublicanData.complementaryDaysEN[today.day - 1])
                        .font(.didot(19, italic: true))
                        .foregroundStyle(Theme.red)
                } else {
                    Text(tr(lang, "JOUR CONSACRÉ", "DEDICATED TO"))
                        .font(.system(size: 9.5, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.gold)
                    Text(today.ruralFR ?? "")
                        .font(.didot(19, italic: true))
                        .foregroundStyle(Theme.red)
                    Spacer()
                    if lang == .en, let english = today.distinctEnglish {
                        Text(english.lowercased())
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(Theme.faded)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 9)
            .overlay(alignment: .top) { Rectangle().fill(Theme.gold.opacity(0.45)).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.gold.opacity(0.45)).frame(height: 1) }
        }
    }
}

// MARK: - Calendar panel with month browsing

struct CalendarPanel: View {
    let rep: RepublicanDate
    let lang: Language
    @Binding var browsedMonth: Int?
    @State private var selectedDay: Int? = nil

    private var displayed: Int { browsedMonth ?? rep.month }

    private static let rangeFormatterFR: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMMM"
        return f
    }()

    private static let rangeFormatterEN: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                monthArrow("chevron.left", step: -1)

                VStack(alignment: .leading, spacing: 1) {
                    Text(displayed == 12 ? "Sans-culottides" : RepublicanData.months[displayed])
                        .font(.didot(20))
                        .foregroundStyle(Theme.blue)
                    Text(subtitle)
                        .font(.system(size: 10.5, design: .serif).italic())
                        .foregroundStyle(Theme.faded)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                monthArrow("chevron.right", step: 1)
            }

            if displayed == 12 {
                complementaryList
            } else {
                monthGrid
            }

            HStack(spacing: 14) {
                if displayed != 12 {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.rest)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.blue.opacity(0.3), lineWidth: 1))
                            .frame(width: 10, height: 10)
                        Text(tr(lang, "décadi, jour de repos", "décadi, the day of rest"))
                    }
                }
                HStack(spacing: 6) {
                    Circle().fill(Theme.red).frame(width: 9, height: 9)
                    Text(tr(lang, "aujourd'hui", "today"))
                }
                Spacer()
                if browsedMonth != nil {
                    Button {
                        browsedMonth = nil
                    } label: {
                        Text(tr(lang, "revenir à aujourd'hui", "back to today"))
                            .font(.system(size: 11, design: .serif))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.red)
                }
            }
            .font(.system(size: 11, design: .serif))
            .foregroundStyle(Theme.faded)
        }
    }

    private func monthArrow(_ icon: String, step: Int) -> some View {
        Button {
            let next = (displayed + step + 13) % 13
            browsedMonth = next == rep.month ? nil : next
            selectedDay = nil
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.gold)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(step < 0 ? tr(lang, "Mois précédent", "Previous month") : tr(lang, "Mois suivant", "Next month"))
    }

    private var subtitle: String {
        let calendar = RepublicanCalendar.localGregorianCalendar
        let length = displayed == 12 ? (rep.isLeapYear ? 6 : 5) : 30
        let start = calendar.date(byAdding: .day, value: displayed * 30, to: rep.yearStart)!
        let end = calendar.date(byAdding: .day, value: length - 1, to: start)!
        let formatter = lang == .fr ? Self.rangeFormatterFR : Self.rangeFormatterEN
        let range = "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        if displayed == 12 {
            return tr(lang, "fêtes de fin d'année", "year-end festivals") + " · \(range)"
        }
        let meaning = lang == .fr
            ? RepublicanData.monthMeanings[displayed]
            : RepublicanData.monthMeaningsEN[displayed]
        return "\(meaning) · \(range)"
    }

    private func isPast(_ day: Int) -> Bool {
        displayed < rep.month || (displayed == rep.month && day < rep.day)
    }

    private var monthGrid: some View {
        let columns = Array(repeating: GridItem(.fixed(38), spacing: 4), count: 10)
        // Headers get their own grid: sharing one with the days would give
        // header 1 and day 1 the same identity, and SwiftUI drops one.
        return VStack(spacing: 4) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<10, id: \.self) { i in
                    Text(RepublicanData.decadeAbbrev[i].uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.4)
                        .foregroundStyle(Theme.blue)
                        .frame(width: 38, height: 20)
                        .background(i == 9 ? Theme.rest : .clear, in: RoundedRectangle(cornerRadius: 5))
                }
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(1...30, id: \.self) { day in
                    let info = RepublicanDay(month: displayed, day: day)
                    Button {
                        selectedDay = day
                    } label: {
                        DayCell(
                            day: day,
                            isToday: displayed == rep.month && day == rep.day,
                            isPast: isPast(day),
                            isRest: info.isDecadi,
                            tooltip: "\(info.title) · \(info.dedication(lang) ?? "")"
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: Binding(
                        get: { selectedDay == day },
                        set: { if !$0 { selectedDay = nil } }
                    )) {
                        DayInfoPopover(lang: lang, rep: rep, month: displayed, day: day)
                    }
                }
            }
        }
    }

    private var complementaryList: some View {
        let count = rep.isLeapYear ? 6 : 5
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(1...count, id: \.self) { day in
                let isToday = rep.isComplementary && day == rep.day
                let info = RepublicanDay(month: 12, day: day)
                Button {
                    selectedDay = day
                } label: {
                    HStack(spacing: 12) {
                        Text("\(day)")
                            .font(.didot(15, bold: isToday))
                            .foregroundStyle(isToday ? .white : Theme.ink)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(isToday ? Theme.red : .clear))
                        Text(info.title)
                            .font(.didot(16))
                            .foregroundStyle(isToday ? Theme.red : Theme.ink)
                        Spacer()
                        if let english = info.dedication(lang) {
                            Text(english)
                                .font(.system(size: 12, design: .serif).italic())
                                .foregroundStyle(Theme.faded)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { selectedDay == day },
                    set: { if !$0 { selectedDay = nil } }
                )) {
                    DayInfoPopover(lang: lang, rep: rep, month: 12, day: day)
                }
                if day < count {
                    Divider()
                }
            }
        }
    }
}

struct DayCell: View {
    let day: Int
    let isToday: Bool
    let isPast: Bool
    let isRest: Bool
    let tooltip: String

    var body: some View {
        Text("\(day)")
            .font(.didot(16, bold: isToday))
            .foregroundStyle(isToday ? .white : isPast ? Theme.faded : Theme.ink)
            .frame(width: 38, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRest ? Theme.rest : .clear)
            )
            .background(
                Circle()
                    .fill(isToday ? Theme.red : .clear)
                    .frame(width: 30, height: 30)
            )
            .contentShape(Rectangle())
            .help(tooltip)
    }
}
