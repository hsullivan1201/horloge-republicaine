import SwiftUI
import AppKit

enum Language: String {
    case fr, en
}

// Tiny bilingual helper: tr(lang, "français", "english")
func tr(_ lang: Language, _ fr: String, _ en: String) -> String {
    lang == .fr ? fr : en
}

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
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Self-colored button so it stays readable on parchment even when the
// system is in dark mode (menu bar panels ignore preferredColorScheme).
struct RevolutionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, design: .serif))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(configuration.isPressed ? Theme.gold.opacity(0.35) : Color.white.opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Theme.gold.opacity(0.7), lineWidth: 1)
            )
    }
}

// Shown when clicking a day: the Republican date and its old-style
// equivalent for the current Republican year.
struct DayInfoPopover: View {
    let lang: Language
    let rep: RepublicanDate  // today, for year context
    let month: Int           // 0-11, or 12 for the complementary days
    let day: Int

    private static let fullFR: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateStyle = .full
        return f
    }()

    private static let fullEN: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateStyle = .full
        return f
    }()

    var body: some View {
        let offset = month == 12 ? 360 + day - 1 : month * 30 + day - 1
        let gregorian = Calendar.current.date(byAdding: .day, value: offset, to: rep.yearStart)!
        let formatter = lang == .fr ? Self.fullFR : Self.fullEN

        VStack(spacing: 5) {
            if month == 12 {
                Text("\(RepublicanData.complementaryDays[day - 1]) · An \(RepublicanCalendar.roman(rep.year))")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                if lang == .en {
                    Text(RepublicanData.complementaryDaysEN[day - 1])
                        .font(.system(size: 11, design: .serif).italic())
                        .foregroundStyle(Theme.red)
                }
            } else {
                Text("\(RepublicanData.decadeDays[(day - 1) % 10]) \(day) \(RepublicanData.months[month]) · An \(RepublicanCalendar.roman(rep.year))")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(lang == .fr
                     ? "✿ \(RepublicanData.ruralDays[month * 30 + day - 1])"
                     : "✿ \(RepublicanData.ruralDaysEN[month * 30 + day - 1]) · \(RepublicanData.ruralDays[month * 30 + day - 1])")
                    .font(.system(size: 11, design: .serif).italic())
                    .foregroundStyle(Theme.red)
            }

            Divider()

            Text(tr(lang, "ancien style : ", "old style: ") + formatter.string(from: gregorian))
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Theme.faded)
        }
        .padding(12)
        .background(Theme.parchment)
    }
}

// MARK: - Menu bar

struct MenuBarLabel: View {
    @State private var now = Date()
    // One decimal second is 0.864 conventional seconds.
    private let timer = Timer.publish(every: 0.864, on: .main, in: .common).autoconnect()

    var body: some View {
        let dec = RepublicanCalendar.decimalTime(for: now)
        Text(String(format: "%d:%02d:%02d", dec.hours, dec.minutes, dec.seconds))
            .monospacedDigit()
            .onReceive(timer) { now = $0 }
    }
}

struct MenuBarPopover: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage("language") private var languageRaw = Language.fr.rawValue
    @State private var now = Date()
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        let lang = Language(rawValue: languageRaw) ?? .fr
        let rep = RepublicanCalendar.date(from: now)
        let dec = RepublicanCalendar.decimalTime(for: now)

        VStack(spacing: 8) {
            Text(String(format: "%d:%02d:%02d", dec.hours, dec.minutes, dec.seconds))
                .font(.system(size: 30, weight: .medium, design: .serif).monospacedDigit())
                .foregroundStyle(Theme.ink)

            VStack(spacing: 2) {
                if rep.isComplementary {
                    Text("\(RepublicanData.complementaryDays[rep.day - 1]) · An \(RepublicanCalendar.roman(rep.year))")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                } else {
                    Text("\(rep.decadeDayName) \(rep.day) \(RepublicanData.months[rep.month]) · An \(RepublicanCalendar.roman(rep.year))")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    if let rural = rep.ruralDayName {
                        Text(lang == .fr
                             ? "✿ \(rural)"
                             : "✿ \(RepublicanData.ruralDaysEN[rep.month * 30 + rep.day - 1]) · \(rural)")
                            .font(.system(size: 11, design: .serif).italic())
                            .foregroundStyle(Theme.red)
                    }
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
        }
        .padding(14)
        .background(Theme.parchment)
        .preferredColorScheme(.light)
        .onReceive(timer) { now = $0 }
    }
}

// MARK: - Main window

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage("language") private var languageRaw = Language.fr.rawValue
    @State private var now = Date()
    @State private var browsedMonth: Int? = nil  // nil = follow today
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private static let frFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMMM yyyy · HH:mm:ss"
        return f
    }()

    private static let enFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM d, yyyy · HH:mm:ss"
        return f
    }()

    var body: some View {
        let lang = Language(rawValue: languageRaw) ?? .fr
        let rep = RepublicanCalendar.date(from: now)
        let dec = RepublicanCalendar.decimalTime(for: now)

        VStack(spacing: 0) {
            TricolorBar()

            VStack(spacing: 16) {
                Text("LIBERTÉ · ÉGALITÉ · FRATERNITÉ")
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .kerning(3)
                    .foregroundStyle(Theme.gold)

                DecimalClockFace(dayFraction: dec.dayFraction)
                    .frame(width: 200, height: 200)

                VStack(spacing: 2) {
                    Text(String(format: "%d:%02d:%02d", dec.hours, dec.minutes, dec.seconds))
                        .font(.system(size: 44, weight: .medium, design: .serif).monospacedDigit())
                        .foregroundStyle(Theme.ink)
                    Text(tr(lang,
                            "heure décimale · 1 jour = 10 h · 1 h = 100 min · 1 min = 100 s",
                            "decimal time · 1 day = 10 h · 1 h = 100 min · 1 min = 100 s"))
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(Theme.faded)
                }

                DateBanner(rep: rep, lang: lang)

                CalendarPanel(rep: rep, lang: lang, browsedMonth: $browsedMonth)

                Text(tr(lang, "heure ancienne : ", "old-style time: ")
                     + (lang == .fr ? Self.frFormatter : Self.enFormatter).string(from: now))
                    .font(.system(size: 11, design: .serif).monospacedDigit())
                    .foregroundStyle(Theme.faded)

                HStack {
                    Picker("", selection: $languageRaw) {
                        Text("FR").tag(Language.fr.rawValue)
                        Text("EN").tag(Language.en.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 90)
                    .labelsHidden()

                    Spacer()

                    Button {
                        openWindow(id: "almanach")
                    } label: {
                        Label(tr(lang, "Almanach", "Almanac"), systemImage: "book.closed")
                            .font(.system(size: 12, design: .serif))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.blue)
                    .help(tr(lang, "Tout le savoir du calendrier républicain",
                             "Everything about the Republican calendar"))
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)

            TricolorBar()
        }
        .background(Theme.parchment)
        .fixedSize()
        // The parchment background is light no matter what, so force light
        // appearance or dark mode draws the controls in white-on-white.
        .preferredColorScheme(.light)
        .onReceive(timer) { now = $0 }
    }
}

struct TricolorBar: View {
    var body: some View {
        HStack(spacing: 0) {
            Theme.blue
            Color.white
            Theme.red
        }
        .frame(height: 8)
    }
}

struct DateBanner: View {
    let rep: RepublicanDate
    let lang: Language

    var body: some View {
        VStack(spacing: 3) {
            if rep.isComplementary {
                Text("\(RepublicanData.complementaryDays[rep.day - 1]) · An \(RepublicanCalendar.roman(rep.year))")
                    .font(.system(size: 19, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(lang == .fr
                     ? "jour complémentaire \(rep.day)"
                     : "\(RepublicanData.complementaryDaysEN[rep.day - 1]) · complementary day \(rep.day)")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Theme.red)
            } else {
                Text("\(rep.decadeDayName) \(rep.day) \(RepublicanData.months[rep.month]) · An \(RepublicanCalendar.roman(rep.year))")
                    .font(.system(size: 19, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                if let rural = rep.ruralDayName {
                    Text(lang == .fr
                         ? "✿ jour consacré : \(rural)"
                         : "✿ day of the \(RepublicanData.ruralDaysEN[rep.month * 30 + rep.day - 1]) · \(rural)")
                        .font(.system(size: 12, design: .serif).italic())
                        .foregroundStyle(Theme.red)
                }
            }
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
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                monthArrow("chevron.left", step: -1)

                VStack(spacing: 1) {
                    Text(displayed == 12 ? "Sans-culottides" : RepublicanData.months[displayed])
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.blue)
                    Text(subtitle)
                        .font(.system(size: 10, design: .serif).italic())
                        .foregroundStyle(Theme.faded)
                }
                .frame(maxWidth: .infinity)

                monthArrow("chevron.right", step: 1)
            }

            if displayed == 12 {
                complementaryList
            } else {
                monthGrid
            }

            if browsedMonth != nil {
                Button {
                    browsedMonth = nil
                } label: {
                    Text(tr(lang, "● revenir à aujourd'hui", "● back to today"))
                        .font(.system(size: 10, design: .serif))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.red)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.gold.opacity(0.6), lineWidth: 1)
        )
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
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        let calendar = Calendar.current
        let start: Date
        let length: Int
        if displayed == 12 {
            start = calendar.date(byAdding: .day, value: 360, to: rep.yearStart)!
            length = rep.isLeapYear ? 6 : 5
        } else {
            start = calendar.date(byAdding: .day, value: displayed * 30, to: rep.yearStart)!
            length = 30
        }
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

    private var monthGrid: some View {
        let columns = Array(repeating: GridItem(.fixed(34), spacing: 3), count: 10)
        return LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<10) { i in
                Text(RepublicanData.decadeAbbrev[i])
                    .font(.system(size: 9, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.blue)
            }
            ForEach(1...30, id: \.self) { day in
                let rural = RepublicanData.ruralDays[displayed * 30 + day - 1]
                let ruralEN = RepublicanData.ruralDaysEN[displayed * 30 + day - 1]
                Button {
                    selectedDay = day
                } label: {
                    DayCell(
                        day: day,
                        isToday: displayed == rep.month && day == rep.day,
                        tooltip: lang == .fr
                            ? "\(RepublicanData.decadeDays[(day - 1) % 10]) \(day) · \(rural)"
                            : "\(RepublicanData.decadeDays[(day - 1) % 10]) \(day) · \(ruralEN) (\(rural))"
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

    private var complementaryList: some View {
        let count = rep.isLeapYear ? 6 : 5
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(1...count, id: \.self) { day in
                let isToday = rep.isComplementary && day == rep.day
                Button {
                    selectedDay = day
                } label: {
                    HStack(spacing: 8) {
                        Text("\(day)")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .frame(width: 16)
                            .foregroundStyle(isToday ? .white : Theme.ink)
                            .background(Circle().fill(isToday ? Theme.red : .clear).frame(width: 20, height: 20))
                        Text(lang == .fr
                             ? RepublicanData.complementaryDays[day - 1]
                             : "\(RepublicanData.complementaryDaysEN[day - 1]) · \(RepublicanData.complementaryDays[day - 1])")
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(isToday ? Theme.red : Theme.ink)
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { selectedDay == day },
                    set: { if !$0 { selectedDay = nil } }
                )) {
                    DayInfoPopover(lang: lang, rep: rep, month: 12, day: day)
                }
            }
        }
    }
}

struct DayCell: View {
    let day: Int
    let isToday: Bool
    let tooltip: String

    var body: some View {
        Text("\(day)")
            .font(.system(size: 13, weight: isToday ? .bold : .regular, design: .serif))
            .foregroundStyle(isToday ? .white : Theme.ink)
            .frame(width: 34, height: 28)
            .background(
                Circle()
                    .fill(isToday ? Theme.red : .clear)
                    .frame(width: 26, height: 26)
            )
            .help(tooltip)
    }
}

// The clock face lives in Theme.swift, shared with the widget extension.
