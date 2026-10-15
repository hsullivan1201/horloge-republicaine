import SwiftUI

enum Language: String {
    case fr, en
}

func tr(_ lang: Language, _ fr: String, _ en: String) -> String {
    lang == .fr ? fr : en
}

private enum MobileTab: Hashable {
    case clock
    case calendar
    case almanac
    case settings
}

struct MobileRootView: View {
    @AppStorage("language") private var languageRaw = Language.fr.rawValue
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
    }
}

private struct ClockScreen: View {
    @AppStorage("language") private var languageRaw = Language.fr.rawValue
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
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let now = context.date
            let rep = RepublicanCalendar.date(from: now)
            let decimal = RepublicanCalendar.decimalTime(for: now)

            ScrollView {
                VStack(spacing: 18) {
                    TricolorStrip()

                    Text("LIBERTÉ · ÉGALITÉ · FRATERNITÉ")
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .tracking(2.4)
                        .foregroundStyle(Theme.gold)
                        .accessibilityAddTraits(.isHeader)

                    DecimalClockFace(dayFraction: decimal.dayFraction)
                        .frame(width: 224, height: 224)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(tr(lang, "Cadran décimal", "Decimal clock face"))

                    VStack(spacing: 4) {
                        Text(String(format: "%d:%02d:%02d", decimal.hours, decimal.minutes, decimal.seconds))
                            .font(.system(size: 46, weight: .medium, design: .serif).monospacedDigit())
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText())
                            .minimumScaleFactor(0.8)
                            .accessibilityLabel(decimalAccessibility(decimal))

                        Text(tr(lang,
                                "heure décimale · 10 h × 100 min × 100 s",
                                "decimal time · 10 h × 100 min × 100 s"))
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(Theme.faded)
                            .multilineTextAlignment(.center)
                    }

                    MobileDateBanner(rep: rep, lang: lang)

                    VStack(spacing: 5) {
                        Text(tr(lang, "HEURE ANCIENNE", "OLD-STYLE TIME"))
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .tracking(1.4)
                            .foregroundStyle(Theme.gold)
                        Text(Self.conventionalDate(now, lang: lang))
                            .font(.system(size: 13, design: .serif).monospacedDigit())
                            .foregroundStyle(Theme.faded)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: openAlmanac) {
                        Label(tr(lang, "Ouvrir l'almanach", "Open the almanac"), systemImage: "book.closed")
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.blue)

                    TricolorStrip()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .background(Theme.parchment.ignoresSafeArea())
        }
        .navigationTitle("Horloge Républicaine")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func decimalAccessibility(_ decimal: DecimalTime) -> String {
        tr(lang,
           "\(decimal.hours) heures, \(decimal.minutes) minutes et \(decimal.seconds) secondes décimales",
           "\(decimal.hours) decimal hours, \(decimal.minutes) minutes, and \(decimal.seconds) seconds")
    }

    private static func conventionalDate(_ date: Date, lang: Language) -> String {
        (lang == .fr ? conventionalFR : conventionalEN).string(from: date)
    }
}

private struct MobileDateBanner: View {
    let rep: RepublicanDate
    let lang: Language

    var body: some View {
        VStack(spacing: 5) {
            if rep.isComplementary {
                Text("\(RepublicanData.complementaryDays[rep.day - 1]) · An \(RepublicanCalendar.roman(rep.year))")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text(lang == .fr
                     ? "jour complémentaire \(rep.day)"
                     : "\(RepublicanData.complementaryDaysEN[rep.day - 1]) · complementary day \(rep.day)")
                    .font(.system(size: 13, design: .serif).italic())
                    .foregroundStyle(Theme.red)
                    .multilineTextAlignment(.center)
            } else {
                Text("\(rep.decadeDayName) \(rep.day) \(RepublicanData.months[rep.month])")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text("An \(RepublicanCalendar.roman(rep.year))")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.gold)

                if let rural = rep.ruralDayName {
                    Text(lang == .fr
                         ? "✿ jour consacré : \(rural)"
                         : "✿ day of the \(RepublicanData.ruralDaysEN[rep.month * 30 + rep.day - 1]) · \(rural)")
                        .font(.system(size: 13, design: .serif).italic())
                        .foregroundStyle(Theme.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.gold.opacity(0.55), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TricolorStrip: View {
    var body: some View {
        HStack(spacing: 0) {
            Theme.blue
            Color.white
            Theme.red
        }
        .frame(height: 6)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

private struct SelectedRepublicanDay: Identifiable {
    let month: Int
    let day: Int
    let republicanDateContext: RepublicanDate

    var id: String { "\(republicanDateContext.year)-\(month)-\(day)" }
}

private struct RepublicanCalendarScreen: View {
    @AppStorage("language") private var languageRaw = Language.fr.rawValue
    @State private var browsedMonth: Int?
    @State private var selectedDay: SelectedRepublicanDay?

    private var lang: Language { Language(rawValue: languageRaw) ?? .fr }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let rep = RepublicanCalendar.date(from: context.date)
            let displayed = browsedMonth ?? rep.month

            ScrollView {
                VStack(spacing: 16) {
                    calendarHeader(displayed: displayed, rep: rep)

                    if displayed == 12 {
                        complementaryDays(rep: rep)
                    } else {
                        monthGrid(displayed: displayed, rep: rep)
                    }

                    if browsedMonth != nil {
                        Button {
                            withAnimation { browsedMonth = nil }
                        } label: {
                            Label(tr(lang, "Revenir à aujourd'hui", "Back to today"), systemImage: "location.fill")
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.red)
                    }
                }
                .padding(16)
            }
            .background(Theme.parchment.ignoresSafeArea())
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
        }
        .navigationTitle(tr(lang, "Calendrier", "Calendar"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func calendarHeader(displayed: Int, rep: RepublicanDate) -> some View {
        HStack(spacing: 12) {
            monthButton("chevron.left", displayed: displayed, rep: rep, step: -1)

            VStack(spacing: 3) {
                Text(displayed == 12 ? "Sans-culottides" : RepublicanData.months[displayed])
                    .font(.system(size: 22, weight: .semibold, design: .serif))
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
                .background(Color.white.opacity(0.45), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(step < 0
                            ? tr(lang, "Mois précédent", "Previous month")
                            : tr(lang, "Mois suivant", "Next month"))
    }

    private func monthGrid(displayed: Int, rep: RepublicanDate) -> some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: 24), spacing: 2), count: 10)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<10, id: \.self) { index in
                Text(RepublicanData.decadeAbbrev[index])
                    .font(.system(size: 8, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.blue)
                    .minimumScaleFactor(0.7)
            }

            ForEach(1...30, id: \.self) { day in
                let isToday = displayed == rep.month && day == rep.day
                Button {
                    selectedDay = SelectedRepublicanDay(
                        month: displayed,
                        day: day,
                        republicanDateContext: rep
                    )
                } label: {
                    Text("\(day)")
                        .font(.system(size: 13, weight: isToday ? .bold : .regular, design: .serif).monospacedDigit())
                        .foregroundStyle(isToday ? Color.white : Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(isToday ? Theme.red : Color.white.opacity(0.34), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dayAccessibility(displayed: displayed, day: day, isToday: isToday))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.gold.opacity(0.55), lineWidth: 1)
        }
    }

    private func complementaryDays(rep: RepublicanDate) -> some View {
        let count = rep.isLeapYear ? 6 : 5

        return VStack(spacing: 0) {
            ForEach(1...count, id: \.self) { day in
                let isToday = rep.isComplementary && day == rep.day
                Button {
                    selectedDay = SelectedRepublicanDay(
                        month: 12,
                        day: day,
                        republicanDateContext: rep
                    )
                } label: {
                    HStack(spacing: 12) {
                        Text("\(day)")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundStyle(isToday ? Color.white : Theme.ink)
                            .frame(width: 34, height: 34)
                            .background(isToday ? Theme.red : Color.white.opacity(0.4), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RepublicanData.complementaryDays[day - 1])
                                .font(.system(size: 15, weight: .semibold, design: .serif))
                                .foregroundStyle(isToday ? Theme.red : Theme.ink)
                            if lang == .en {
                                Text(RepublicanData.complementaryDaysEN[day - 1])
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
        .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.gold.opacity(0.55), lineWidth: 1)
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

    private func dayAccessibility(displayed: Int, day: Int, isToday: Bool) -> String {
        let weekday = RepublicanData.decadeDays[(day - 1) % 10]
        let rural = lang == .fr
            ? RepublicanData.ruralDays[displayed * 30 + day - 1]
            : RepublicanData.ruralDaysEN[displayed * 30 + day - 1]
        let today = isToday ? tr(lang, ", aujourd'hui", ", today") : ""
        return "\(weekday) \(day), \(rural)\(today)"
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if month == 12 {
                Text("\(RepublicanData.complementaryDays[day - 1]) · An \(RepublicanCalendar.roman(rep.year))")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                if lang == .en {
                    Text(RepublicanData.complementaryDaysEN[day - 1])
                        .font(.system(size: 14, design: .serif).italic())
                        .foregroundStyle(Theme.red)
                }
            } else {
                Text("\(RepublicanData.decadeDays[(day - 1) % 10]) \(day) \(RepublicanData.months[month]) · An \(RepublicanCalendar.roman(rep.year))")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(lang == .fr
                     ? "✿ \(RepublicanData.ruralDays[month * 30 + day - 1])"
                     : "✿ \(RepublicanData.ruralDaysEN[month * 30 + day - 1]) · \(RepublicanData.ruralDays[month * 30 + day - 1])")
                    .font(.system(size: 14, design: .serif).italic())
                    .foregroundStyle(Theme.red)
            }

            Divider()

            Label(gregorianDate, systemImage: "calendar")
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(Theme.faded)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var gregorianDate: String {
        let offset = month == 12 ? 360 + day - 1 : month * 30 + day - 1
        let date = RepublicanCalendar.localGregorianCalendar.date(byAdding: .day, value: offset, to: rep.yearStart)!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        formatter.dateStyle = .full
        return tr(lang, "ancien style : ", "old style: ") + formatter.string(from: date)
    }
}

private struct MobileSettingsView: View {
    @AppStorage("language") private var languageRaw = Language.fr.rawValue
    @AppStorage("chime") private var chime = true

    private var lang: Language { Language(rawValue: languageRaw) ?? .fr }

    var body: some View {
        Form {
            Section(tr(lang, "Langue", "Language")) {
                Picker(tr(lang, "Langue", "Language"), selection: $languageRaw) {
                    Text("Français").tag(Language.fr.rawValue)
                    Text("English").tag(Language.en.rawValue)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle(tr(lang, "Carillon de l'heure décimale", "Decimal-hour chime"), isOn: $chime)

                Button {
                    ChimeController.shared.preview()
                } label: {
                    Label(tr(lang, "Écouter un aperçu", "Play a preview"), systemImage: "speaker.wave.2")
                }
            } footer: {
                Text(tr(lang,
                        "Le carillon sonne lorsque l'app est ouverte. iOS suspend les minuteries quand l'app passe en arrière-plan.",
                        "The chime sounds while the app is open. iOS suspends timers after the app moves to the background."))
            }

            Section(tr(lang, "Widget d'écran d'accueil", "Home Screen widget")) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(tr(lang, "Petit : heure et date républicaines", "Small: Republican time and date"), systemImage: "square")
                    Label(tr(lang, "Moyen : ajoute le cadran décimal", "Medium: adds the decimal dial"), systemImage: "rectangle")

                    Text(tr(lang,
                            "Après avoir lancé l'app, touchez longuement l'écran d'accueil, choisissez Modifier puis Ajouter un widget, et cherchez « Horloge Républicaine ». Le widget suit la langue de l'iPhone.",
                            "After launching the app, touch and hold the Home Screen, choose Edit then Add Widget, and search for “Horloge Républicaine.” The widget follows the iPhone's language."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section(tr(lang, "À propos", "About")) {
                LabeledContent(tr(lang, "Calendrier", "Calendar"), value: tr(lang, "Républicain français", "French Republican"))
                LabeledContent(tr(lang, "Version", "Version"), value: "1.0")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.parchment)
        .navigationTitle(tr(lang, "Réglages", "Settings"))
    }
}
