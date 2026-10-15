import SwiftUI
import UIKit
import WidgetKit

// Side effects of changing a setting: the widget re-reads the language and
// appearance from the app group.
enum Settings {
    static func changed() {
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

private enum MobileTab: Hashable {
    case clock
    case calendar
    case almanac
    case settings
}

struct MobileRootView: View {
    @AppStorage("language", store: AppGroup.defaults) private var languageRaw = Language.fr.rawValue
    @AppStorage("appearance", store: AppGroup.defaults) private var appearanceRaw = Appearance.auto.rawValue
    @State private var selection = MobileTab.clock

    private var lang: Language { Language(rawValue: languageRaw) ?? .fr }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                ClockScreen {
                    selection = .almanac
                }
            }
            .tabItem {
                Label(tr(lang, "Horloge", "Clock"), systemImage: "clock")
            }
            .tag(MobileTab.clock)

            NavigationStack {
                RepublicanCalendarScreen()
            }
            .tabItem {
                Label(tr(lang, "Calendrier", "Calendar"), systemImage: "calendar")
            }
            .tag(MobileTab.calendar)

            AlmanachView()
                .tabItem {
                    Label(tr(lang, "Almanach", "Almanac"), systemImage: "book.closed")
                }
                .tag(MobileTab.almanac)

            NavigationStack {
                MobileSettingsView()
            }
            .tabItem {
                Label(tr(lang, "Réglages", "Settings"), systemImage: "gearshape")
            }
            .tag(MobileTab.settings)
        }
        .tint(Theme.blue)
        .onOpenURL { url in
            switch url.host {
            case "calendar": selection = .calendar
            case "almanac": selection = .almanac
            case "settings": selection = .settings
            default: selection = .clock
            }
        }
        .onAppear(perform: applyAppearance)
        .onChange(of: appearanceRaw) { applyAppearance() }
    }

    // Set on the windows rather than with preferredColorScheme, which does
    // not reliably return to the system setting once it has forced one, and
    // also misses sheets.
    private func applyAppearance() {
        let style: UIUserInterfaceStyle
        switch Appearance(rawValue: appearanceRaw) ?? .auto {
        case .auto: style = .unspecified
        case .jour: style = .light
        case .nuit: style = .dark
        }
        for scene in UIApplication.shared.connectedScenes {
            (scene as? UIWindowScene)?.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}

// MARK: - Clock

private struct ClockScreen: View {
    @AppStorage("language", store: AppGroup.defaults) private var languageRaw = Language.fr.rawValue
    @StateObject private var ticker = DecimalTicker()
    let openAlmanac: () -> Void

    private var lang: Language { Language(rawValue: languageRaw) ?? .fr }

    private static let conventionalFR: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM yyyy · HH:mm:ss"
        return formatter
    }()

    private static let conventionalEN: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d, yyyy · h:mm:ss a"
        return formatter
    }()

    var body: some View {
        let now = ticker.now
        let rep = RepublicanCalendar.date(from: now)
        let decimal = RepublicanCalendar.decimalTime(for: now)

        ScrollView {
            VStack(spacing: 20) {
                Text("LIBERTÉ · ÉGALITÉ · FRATERNITÉ")
                    .font(.didot(11))
                    .tracking(2.4)
                    .foregroundStyle(Theme.gold)
                    .accessibilityAddTraits(.isHeader)

                DecimalClockFace(time: decimal)
                    .frame(width: 300, height: 300)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(tr(lang, "Cadran décimal", "Decimal clock face"))

                VStack(spacing: 6) {
                    DidotTime(text: decimal.text, size: 54)
                        .accessibilityLabel(decimalAccessibility(decimal))

                    Text((lang == .fr ? Self.conventionalFR : Self.conventionalEN).string(from: now))
                        .font(.system(size: 13, design: .serif).monospacedDigit())
                        .foregroundStyle(Theme.faded)
                        .multilineTextAlignment(.center)
                }

                MobileDateBanner(rep: rep, lang: lang)

                Button(action: openAlmanac) {
                    Label(tr(lang, "Ouvrir l'almanach", "Open the almanac"), systemImage: "book.closed")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(Theme.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Theme.parchment.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { TricolorBar(height: 4) }
        .navigationTitle("Horloge Républicaine")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func decimalAccessibility(_ decimal: DecimalTime) -> String {
        tr(lang,
           "\(decimal.hours) heures, \(decimal.minutes) minutes et \(decimal.seconds) secondes décimales",
           "\(decimal.hours) decimal hours, \(decimal.minutes) minutes, and \(decimal.seconds) seconds")
    }
}

private struct MobileDateBanner: View {
    let rep: RepublicanDate
    let lang: Language

    var body: some View {
        let today = rep.republicanDay

        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(today.title)
                    .font(.didot(28))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                Text(rep.yearText.uppercased())
                    .font(.didot(15))
                    .tracking(1.4)
                    .foregroundStyle(Theme.gold)
            }

            Rectangle().fill(Theme.gold.opacity(0.45)).frame(height: 1)

            VStack(spacing: 3) {
                Text(today.isComplementary
                     ? "SANS-CULOTTIDE"
                     : tr(lang, "JOUR CONSACRÉ", "DEDICATED TO"))
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.gold)
                if today.isComplementary {
                    Text(lang == .fr
                         ? "jour complémentaire \(today.day)"
                         : RepublicanData.complementaryDaysEN[today.day - 1])
                        .font(.didot(22, italic: true))
                        .foregroundStyle(Theme.red)
                } else {
                    Text(today.ruralFR ?? "")
                        .font(.didot(24, italic: true))
                        .foregroundStyle(Theme.red)
                    if lang == .en, let english = today.distinctEnglish {
                        Text(english.lowercased())
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(Theme.faded)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Theme.cell, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.gold.opacity(0.5), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Calendar

private struct SelectedRepublicanDay: Identifiable {
    let month: Int
    let day: Int
    let republicanDateContext: RepublicanDate

    var id: String { "\(republicanDateContext.year)-\(month)-\(day)" }
}

private struct RepublicanCalendarScreen: View {
    @AppStorage("language", store: AppGroup.defaults) private var languageRaw = Language.fr.rawValue
    @State private var browsedMonth: Int?
    @State private var selectedDay: SelectedRepublicanDay?
    // Only needs to notice midnight.
    @StateObject private var ticker = DecimalTicker(every: 100)

    private var lang: Language { Language(rawValue: languageRaw) ?? .fr }

    var body: some View {
        let rep = RepublicanCalendar.date(from: ticker.now)
        let displayed = browsedMonth ?? rep.month

        ScrollView {
            VStack(spacing: 18) {
                calendarHeader(displayed: displayed, rep: rep)

                if displayed == 12 {
                    complementaryDays(rep: rep)
                } else {
                    monthGrid(displayed: displayed, rep: rep)
                    legend
                }

                if browsedMonth != nil {
                    Button {
                        withAnimation { browsedMonth = nil }
                    } label: {
                        Label(tr(lang, "Revenir à aujourd'hui", "Back to today"), systemImage: "location.fill")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.red)
                }
            }
            .padding(16)
        }
        .background(Theme.parchment.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { TricolorBar(height: 4) }
        .sheet(item: $selectedDay) { selection in
            MobileDaySheet(
                lang: lang,
                rep: selection.republicanDateContext,
                month: selection.month,
                day: selection.day
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationTitle(tr(lang, "Calendrier", "Calendar"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func calendarHeader(displayed: Int, rep: RepublicanDate) -> some View {
        HStack(spacing: 12) {
            monthButton("chevron.left", displayed: displayed, rep: rep, step: -1)

            VStack(spacing: 3) {
                Text(displayed == 12 ? "Sans-culottides" : RepublicanData.months[displayed])
                    .font(.didot(28))
                    .foregroundStyle(Theme.blue)
                Text(monthSubtitle(displayed: displayed, rep: rep))
                    .font(.system(size: 12, design: .serif).italic())
                    .foregroundStyle(Theme.faded)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            monthButton("chevron.right", displayed: displayed, rep: rep, step: 1)
        }
        .padding(.vertical, 4)
    }

    private func monthButton(_ symbol: String, displayed: Int, rep: RepublicanDate, step: Int) -> some View {
        Button {
            let next = (displayed + step + 13) % 13
            withAnimation {
                browsedMonth = next == rep.month ? nil : next
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.gold)
                .frame(width: 44, height: 44)
                .background(Theme.cell, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(step < 0
                            ? tr(lang, "Mois précédent", "Previous month")
                            : tr(lang, "Mois suivant", "Next month"))
    }

    private func monthGrid(displayed: Int, rep: RepublicanDate) -> some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: 24), spacing: 3), count: 10)

        // Headers get their own grid: sharing one with the days would give
        // header 1 and day 1 the same identity, and SwiftUI drops one.
        return VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<10, id: \.self) { index in
                    Text(RepublicanData.decadeAbbrev[index].uppercased())
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundStyle(Theme.blue)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 22)
                        .background(index == 9 ? Theme.rest : .clear, in: RoundedRectangle(cornerRadius: 6))
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(1...30, id: \.self) { day in
                    let info = RepublicanDay(month: displayed, day: day)
                    let isToday = displayed == rep.month && day == rep.day
                    let isPast = displayed < rep.month || (displayed == rep.month && day < rep.day)
                    Button {
                        selectedDay = SelectedRepublicanDay(
                            month: displayed,
                            day: day,
                            republicanDateContext: rep
                        )
                    } label: {
                        Text("\(day)")
                            .font(.didot(18, bold: isToday))
                            .foregroundStyle(isToday ? Color.white : isPast ? Theme.faded : Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(info.isDecadi ? Theme.rest : .clear, in: RoundedRectangle(cornerRadius: 7))
                            .background {
                                Circle()
                                    .fill(isToday ? Theme.red : .clear)
                                    .frame(width: 34, height: 34)
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(dayAccessibility(info, isToday: isToday))
                }
            }
        }
        .padding(12)
        .background(Theme.cell, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.gold.opacity(0.5), lineWidth: 1)
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.rest)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.blue.opacity(0.3), lineWidth: 1))
                    .frame(width: 11, height: 11)
                Text(tr(lang, "décadi, jour de repos", "décadi, the day of rest"))
            }
            HStack(spacing: 6) {
                Circle().fill(Theme.red).frame(width: 10, height: 10)
                Text(tr(lang, "aujourd'hui", "today"))
            }
        }
        .font(.system(size: 12, design: .serif))
        .foregroundStyle(Theme.faded)
        .accessibilityHidden(true)
    }

    private func complementaryDays(rep: RepublicanDate) -> some View {
        let count = rep.isLeapYear ? 6 : 5

        return VStack(spacing: 0) {
            ForEach(1...count, id: \.self) { day in
                let isToday = rep.isComplementary && day == rep.day
                let info = RepublicanDay(month: 12, day: day)
                Button {
                    selectedDay = SelectedRepublicanDay(
                        month: 12,
                        day: day,
                        republicanDateContext: rep
                    )
                } label: {
                    HStack(spacing: 12) {
                        Text("\(day)")
                            .font(.didot(17, bold: isToday))
                            .foregroundStyle(isToday ? Color.white : Theme.ink)
                            .frame(width: 34, height: 34)
                            .background(isToday ? Theme.red : Theme.cell, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(info.title)
                                .font(.didot(18))
                                .foregroundStyle(isToday ? Theme.red : Theme.ink)
                            if let english = info.dedication(lang) {
                                Text(english)
                                    .font(.system(size: 12, design: .serif).italic())
                                    .foregroundStyle(Theme.faded)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if day < count { Divider() }
            }
        }
        .padding(.horizontal, 14)
        .background(Theme.cell, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.gold.opacity(0.5), lineWidth: 1)
        }
    }

    private func monthSubtitle(displayed: Int, rep: RepublicanDate) -> String {
        let calendar = RepublicanCalendar.localGregorianCalendar
        let startOffset = displayed == 12 ? 360 : displayed * 30
        let length = displayed == 12 ? (rep.isLeapYear ? 6 : 5) : 30
        let start = calendar.date(byAdding: .day, value: startOffset, to: rep.yearStart)!
        let end = calendar.date(byAdding: .day, value: length - 1, to: start)!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        let range = "\(formatter.string(from: start)) – \(formatter.string(from: end))"

        if displayed == 12 {
            return tr(lang, "fêtes de fin d'année", "year-end festivals") + " · \(range)"
        }
        let meaning = lang == .fr
            ? RepublicanData.monthMeanings[displayed]
            : RepublicanData.monthMeaningsEN[displayed]
        return "\(meaning) · \(range)"
    }

    private func dayAccessibility(_ info: RepublicanDay, isToday: Bool) -> String {
        let today = isToday ? tr(lang, ", aujourd'hui", ", today") : ""
        let rest = info.isDecadi ? tr(lang, ", jour de repos", ", day of rest") : ""
        return "\(info.title), \(info.dedication(lang) ?? "")\(rest)\(today)"
    }
}

private struct MobileDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let lang: Language
    let rep: RepublicanDate
    let month: Int
    let day: Int

    var body: some View {
        NavigationStack {
            DayDetails(lang: lang, rep: rep, month: month, day: day)
                .padding(22)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Theme.parchment.ignoresSafeArea())
                .navigationTitle(tr(lang, "Détail du jour", "Day details"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(tr(lang, "Fermer", "Done")) { dismiss() }
                    }
                }
        }
    }
}

// AlmanachView uses this on macOS as a popover and iOS presents it as a sheet.
struct DayInfoPopover: View {
    let lang: Language
    let rep: RepublicanDate
    let month: Int
    let day: Int

    var body: some View {
        DayDetails(lang: lang, rep: rep, month: month, day: day)
            .padding(16)
            .background(Theme.parchment)
            .presentationDetents([.medium])
    }
}

private struct DayDetails: View {
    let lang: Language
    let rep: RepublicanDate
    let month: Int
    let day: Int

    private static let fullFR: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .full
        return formatter
    }()

    private static let fullEN: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .full
        return formatter
    }()

    var body: some View {
        let target = RepublicanDay(month: month, day: day)

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(target.title)
                    .font(.didot(26))
                    .foregroundStyle(Theme.ink)
                Text(rep.yearText.uppercased())
                    .font(.didot(14))
                    .tracking(1.2)
                    .foregroundStyle(Theme.gold)
            }
            if let dedication = target.dedication(lang) {
                Text(target.isComplementary ? dedication : "✿ \(dedication)")
                    .font(.didot(19, italic: true))
                    .foregroundStyle(Theme.red)
            }

            Divider()

            Label(gregorianDate(target), systemImage: "calendar")
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(Theme.faded)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func gregorianDate(_ target: RepublicanDay) -> String {
        let formatter = lang == .fr ? Self.fullFR : Self.fullEN
        return tr(lang, "ancien style : ", "old style: ")
            + formatter.string(from: target.gregorianDate(yearStart: rep.yearStart))
    }
}

// MARK: - Settings

private struct MobileSettingsView: View {
    @AppStorage("language", store: AppGroup.defaults) private var languageRaw = Language.fr.rawValue
    @AppStorage("appearance", store: AppGroup.defaults) private var appearanceRaw = Appearance.auto.rawValue
    @AppStorage("chime", store: AppGroup.defaults) private var chime = true

    private var lang: Language { Language(rawValue: languageRaw) ?? .fr }

    var body: some View {
        Form {
            Section(tr(lang, "Langue", "Language")) {
                Picker(tr(lang, "Langue", "Language"), selection: settingBinding($languageRaw)) {
                    Text("Français").tag(Language.fr.rawValue)
                    Text("English").tag(Language.en.rawValue)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Theme.cell)
            }

            Section {
                Picker(tr(lang, "Apparence", "Appearance"), selection: settingBinding($appearanceRaw)) {
                    ForEach(Appearance.allCases, id: \.self) { appearance in
                        Text(appearance.label(lang)).tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Theme.cell)
            } header: {
                Text(tr(lang, "Apparence", "Appearance"))
            } footer: {
                Text(tr(lang,
                        "Nuit, c'est l'almanach à la chandelle. Auto suit le réglage de l'iPhone. Le widget suit aussi.",
                        "Night is the almanac by candlelight. Auto follows the iPhone's setting. The widget follows along."))
            }

            Section {
                Toggle(tr(lang, "Carillon de l'heure décimale", "Decimal-hour chime"), isOn: $chime)
                    .tint(Theme.blue)
                    .listRowBackground(Theme.cell)

                Button {
                    ChimeController.shared.preview()
                } label: {
                    Label(tr(lang, "Écouter un aperçu", "Play a preview"), systemImage: "speaker.wave.2")
                }
                .listRowBackground(Theme.cell)
            } footer: {
                Text(tr(lang,
                        "Le carillon sonne lorsque l'app est ouverte. iOS suspend les minuteries quand l'app passe en arrière-plan.",
                        "The chime sounds while the app is open. iOS suspends timers after the app moves to the background."))
            }

            Section(tr(lang, "Widgets", "Widgets")) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(tr(lang, "Écran d'accueil : petit et moyen (avec le cadran)", "Home Screen: small and medium (with the dial)"), systemImage: "square.grid.2x2")
                    Label(tr(lang, "Écran verrouillé : cadran rond, rectangle et ligne", "Lock Screen: round dial, rectangle, and inline"), systemImage: "lock")
                    Label(tr(lang, "En veille (StandBy) : le petit widget", "StandBy: the small widget"), systemImage: "platter.filled.bottom.iphone")

                    Text(tr(lang,
                            "Touchez longuement l'écran d'accueil ou l'écran verrouillé, choisissez Modifier puis Ajouter un widget, et cherchez « Horloge Républicaine ». La barre sous l'heure avance en direct dans l'heure décimale.",
                            "Touch and hold the Home Screen or Lock Screen, choose Edit then Add Widget, and search for “Horloge Républicaine.” The bar under the time fills live through the decimal hour."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .listRowBackground(Theme.cell)
            }

            Section(tr(lang, "À propos", "About")) {
                LabeledContent(tr(lang, "Calendrier", "Calendar"), value: tr(lang, "Républicain français", "French Republican"))
                    .listRowBackground(Theme.cell)
                LabeledContent(tr(lang, "Version", "Version"), value: "1.1")
                    .listRowBackground(Theme.cell)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.parchment)
        .navigationTitle(tr(lang, "Réglages", "Settings"))
    }
}
