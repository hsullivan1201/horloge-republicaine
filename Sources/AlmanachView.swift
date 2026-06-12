import SwiftUI

// The lore browser: everything about the Republican calendar and decimal
// time, in French or English.
struct AlmanachView: View {
    enum Page: Hashable {
        case system
        case decade
        case month(Int)
        case complementary
        case converter
    }

    @AppStorage("language") private var languageRaw = Language.fr.rawValue
    @State private var selection: Page? = .system

    private var lang: Language { Language(rawValue: languageRaw) ?? .fr }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    Text(tr(lang, "Le système", "The system")).tag(Page.system)
                    Text(tr(lang, "La décade", "The décade")).tag(Page.decade)
                    Text("Sans-culottides").tag(Page.complementary)
                    Text(tr(lang, "Le convertisseur", "The converter")).tag(Page.converter)
                }
                Section(tr(lang, "Les mois", "The months")) {
                    ForEach(0..<12, id: \.self) { m in
                        HStack {
                            Text(RepublicanData.months[m])
                            Spacer()
                            Text(RepublicanData.monthTranslations[m])
                                .foregroundStyle(.secondary)
                                .font(.system(size: 11))
                        }
                        .tag(Page.month(m))
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210)
        } detail: {
            ScrollView {
                Group {
                    switch selection ?? .system {
                    case .system: SystemPage(lang: lang)
                    case .decade: DecadePage(lang: lang)
                    case .month(let m): MonthPage(lang: lang, month: m)
                    case .complementary: ComplementaryPage(lang: lang)
                    case .converter: ConverterPage(lang: lang)
                    }
                }
                .frame(maxWidth: 560, alignment: .leading)
                .padding(28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.parchment)
        }
        .frame(minWidth: 700, minHeight: 480)
        .preferredColorScheme(.light)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("", selection: $languageRaw) {
                    Text("FR").tag(Language.fr.rawValue)
                    Text("EN").tag(Language.en.rawValue)
                }
                .pickerStyle(.segmented)
                .frame(width: 90)
            }
        }
    }
}

// MARK: - Shared typography

private struct PageTitle: View {
    let text: String
    let subtitle: String?

    init(_ text: String, subtitle: String? = nil) {
        self.text = text
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, design: .serif).italic())
                    .foregroundStyle(Theme.gold)
            }
            Rectangle()
                .fill(Theme.gold.opacity(0.5))
                .frame(height: 1)
                .padding(.top, 6)
        }
        .padding(.bottom, 8)
    }
}

private struct Prose: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, design: .serif))
            .foregroundStyle(Theme.ink)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Pages

private struct SystemPage: View {
    let lang: Language

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PageTitle(
                tr(lang, "Le temps républicain", "Republican time"),
                subtitle: tr(lang, "un jour, dix heures", "one day, ten hours")
            )

            Prose(tr(lang,
                """
                Le 5 octobre 1793, la Convention nationale adopte le calendrier \
                républicain, et avec lui le temps décimal : le jour est divisé en \
                10 heures, chaque heure en 100 minutes, chaque minute en 100 \
                secondes. Midi tombe à 5 heures, et une journée entière compte \
                100 000 secondes décimales.
                """,
                """
                On October 5, 1793, the National Convention adopted the Republican \
                calendar, and with it decimal time: the day is divided into 10 \
                hours, each hour into 100 minutes, each minute into 100 seconds. \
                Noon falls at 5 o'clock, and a full day has exactly 100,000 \
                decimal seconds.
                """))

            Prose(tr(lang,
                """
                Une heure décimale vaut 2 h 24 anciennes, une minute décimale \
                1 min 26,4 s, et une seconde décimale 0,864 s. Des horlogers \
                fabriquèrent de véritables montres à 10 heures, mais le temps \
                décimal ne fut obligatoire que dix-sept mois environ avant d'être \
                suspendu en 1795. Personne ne voulait remplacer sa montre.
                """,
                """
                One decimal hour is 2 h 24 min of old time, one decimal minute is \
                1 min 26.4 s, and one decimal second is 0.864 s. Watchmakers built \
                real 10-hour watches, but decimal time was only mandatory for \
                about seventeen months before being suspended in 1795. Nobody \
                wanted to replace their watch.
                """))

            Prose(tr(lang,
                """
                Le calendrier, lui, tint plus longtemps. Conçu par Gilbert Romme \
                et nommé par le poète Fabre d'Églantine, il compte 12 mois de \
                30 jours exactement, soit trois décades de 10 jours, plus 5 ou 6 \
                jours de fête en fin d'année, les sans-culottides. L'an I commence \
                le 22 septembre 1792, jour de la proclamation de la République et \
                de l'équinoxe d'automne. Napoléon l'abolit au 1er janvier 1806.
                """,
                """
                The calendar itself lasted longer. Designed by Gilbert Romme and \
                named by the poet Fabre d'Églantine, it has 12 months of exactly \
                30 days each, made of three 10-day décades, plus 5 or 6 festival \
                days at the end of the year, the sans-culottides. Year I begins on \
                September 22, 1792, the day the Republic was proclaimed, which was \
                also the autumn equinox. Napoleon abolished it on January 1, 1806.
                """))

            Prose(tr(lang,
                """
                À la place des saints du calendrier grégorien, chaque jour célèbre \
                une plante, un minéral, un animal ou un outil agricole : le raisin, \
                le safran, la pomme de terre, le bœuf, la charrue. Chaque quintidi \
                honore un animal, chaque décadi un outil.
                """,
                """
                Instead of the saints of the Gregorian calendar, every day \
                celebrates a plant, mineral, animal or farm tool: the grape, \
                saffron, the potato, the ox, the plough. Every quintidi honors an \
                animal, every décadi a tool.
                """))
        }
    }
}

private struct DecadePage: View {
    let lang: Language

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PageTitle(
                tr(lang, "La décade", "The décade"),
                subtitle: tr(lang, "la semaine de dix jours", "the ten-day week")
            )

            Prose(tr(lang,
                """
                La semaine de sept jours disparaît au profit de la décade. Les \
                noms des jours sont d'une simplicité toute révolutionnaire : un \
                ordinal latin suivi de « di », le jour. Le décadi remplaçait le \
                dimanche comme jour de repos, ce qui faisait un jour de congé \
                tous les dix jours au lieu de sept. Ce détail n'a pas aidé à la \
                popularité du système.
                """,
                """
                The seven-day week was replaced by the décade. The day names have \
                a very revolutionary simplicity: a Latin ordinal followed by \
                "di", meaning day. Décadi replaced Sunday as the day of rest, \
                which meant one day off every ten days instead of seven. This \
                detail did not help the system's popularity.
                """))

            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { i in
                    let root = RepublicanData.decadeRoots[i]
                    HStack {
                        Text(RepublicanData.decadeDays[i])
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.blue)
                            .frame(width: 100, alignment: .leading)
                        Text(lang == .fr
                             ? "du latin \(root.latin), « \(root.fr) »"
                             : "from Latin \(root.latin), \"\(root.en)\"")
                            .font(.system(size: 13, design: .serif).italic())
                            .foregroundStyle(Theme.faded)
                        Spacer()
                        if i == 4 {
                            Text(tr(lang, "jour des animaux", "animal day"))
                                .font(.system(size: 11, design: .serif))
                                .foregroundStyle(Theme.red)
                        } else if i == 9 {
                            Text(tr(lang, "outils & repos", "tools & rest"))
                                .font(.system(size: 11, design: .serif))
                                .foregroundStyle(Theme.red)
                        }
                    }
                    .padding(.vertical, 7)
                    if i < 9 {
                        Divider()
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.gold.opacity(0.6), lineWidth: 1)
            )
        }
    }
}

private struct MonthPage: View {
    let lang: Language
    let month: Int
    @State private var selectedDay: Int? = nil

    var body: some View {
        let rep = RepublicanCalendar.date(from: Date())
        let season = month / 3

        VStack(alignment: .leading, spacing: 14) {
            PageTitle(
                RepublicanData.months[month],
                subtitle: lang == .fr
                    ? "\(RepublicanData.monthMeanings[month]) · \(RepublicanData.seasonsFR[season])"
                    : "\(RepublicanData.monthMeaningsEN[month]) · \(RepublicanData.seasonsEN[season])"
            )

            Prose(lang == .fr
                ? "Étymologie : \(RepublicanData.monthEtymologiesFR[month])."
                : "Etymology: \(RepublicanData.monthEtymologiesEN[month]), translated as \"\(RepublicanData.monthTranslations[month])\".")

            Prose(tr(lang,
                """
                Les mois d'une même saison riment entre eux : -aire en automne, \
                -ôse en hiver, -al au printemps, -idor en été. La presse anglaise \
                s'en est moquée en surnommant celui-ci « \(RepublicanData.monthNicknames[month]) ».
                """,
                """
                The months of each season rhyme: -aire in autumn, -ôse in winter, \
                -al in spring, -idor in summer. The British press mocked them, \
                nicknaming this one "\(RepublicanData.monthNicknames[month])".
                """))

            VStack(spacing: 0) {
                ForEach(1...30, id: \.self) { day in
                    let isToday = month == rep.month && day == rep.day
                    Button {
                        selectedDay = day
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(day)")
                                .font(.system(size: 12, weight: .bold, design: .serif).monospacedDigit())
                                .foregroundStyle(isToday ? .white : Theme.faded)
                                .frame(width: 22, height: 20)
                                .background(Circle().fill(isToday ? Theme.red : .clear))
                            Text(RepublicanData.decadeDays[(day - 1) % 10])
                                .font(.system(size: 12, design: .serif))
                                .foregroundStyle(Theme.faded)
                                .frame(width: 64, alignment: .leading)
                            Text(RepublicanData.ruralDays[month * 30 + day - 1])
                                .font(.system(size: 13, weight: isToday ? .semibold : .regular, design: .serif))
                                .foregroundStyle(isToday ? Theme.red : Theme.ink)
                            Spacer()
                            Text(RepublicanData.ruralDaysEN[month * 30 + day - 1])
                                .font(.system(size: 12, design: .serif).italic())
                                .foregroundStyle(Theme.faded)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: Binding(
                        get: { selectedDay == day },
                        set: { if !$0 { selectedDay = nil } }
                    )) {
                        DayInfoPopover(lang: lang, rep: rep, month: month, day: day)
                    }
                    .padding(.vertical, 3)
                    if day % 10 == 0 && day < 30 {
                        Divider().padding(.vertical, 4)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.gold.opacity(0.6), lineWidth: 1)
            )
        }
    }
}

private struct ConverterPage: View {
    let lang: Language
    @State private var gregDay: Int
    @State private var gregMonth: Int  // 1-12
    @State private var gregYear: Int
    @State private var repYear: Int
    @State private var repMonth: Int
    @State private var repDay: Int
    @State private var oldHour: Int
    @State private var oldMinute: Int
    @State private var decHour: Int
    @State private var decMinute: Int

    init(lang: Language) {
        self.lang = lang
        let now = Date()
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let today = RepublicanCalendar.date(from: now)
        let dec = RepublicanCalendar.decimalTime(for: now)
        _gregDay = State(initialValue: comps.day!)
        _gregMonth = State(initialValue: comps.month!)
        _gregYear = State(initialValue: comps.year!)
        _repYear = State(initialValue: today.year)
        _repMonth = State(initialValue: today.month)
        _repDay = State(initialValue: today.day)
        _oldHour = State(initialValue: comps.hour!)
        _oldMinute = State(initialValue: comps.minute!)
        _decHour = State(initialValue: dec.hours)
        _decMinute = State(initialValue: dec.minutes)
    }

    private static let monthSymbolsFR: [String] = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        return f.monthSymbols
    }()

    private static let monthSymbolsEN: [String] = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        return f.monthSymbols
    }()

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

    private var formatter: DateFormatter { lang == .fr ? Self.fullFR : Self.fullEN }

    private var maxDay: Int {
        repMonth == 12 ? (RepublicanCalendar.isLeapRepublicanYear(repYear) ? 6 : 5) : 30
    }

    private var gregMaxDay: Int {
        let calendar = Calendar.current
        let anchor = calendar.date(from: DateComponents(year: gregYear, month: gregMonth))!
        return calendar.range(of: .day, in: .month, for: anchor)!.count
    }

    // Noon, so DST shifts can't nudge the day.
    private var gregorianInput: Date {
        Calendar.current.date(from: DateComponents(
            year: gregYear, month: gregMonth, day: min(gregDay, gregMaxDay), hour: 12
        ))!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PageTitle(
                tr(lang, "Le convertisseur", "The converter"),
                subtitle: tr(lang, "d'un calendrier à l'autre", "from one calendar to the other")
            )

            Prose(tr(lang,
                """
                Les documents de la Révolution sont tous datés en style \
                républicain. Voici de quoi les déchiffrer, et de quoi savoir \
                quel jour vous êtes né dans le calendrier de la République.
                """,
                """
                Documents from the Revolution are all dated in Republican style. \
                Here is how to decipher them, and how to find out what day you \
                were born on in the calendar of the Republic.
                """))

            converterPanel(title: tr(lang, "Ancien style → républicain", "Old style → Republican")) {
                HStack(spacing: 8) {
                    Picker("", selection: $gregDay) {
                        ForEach(1...gregMaxDay, id: \.self) { d in
                            Text("\(d)").tag(d)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 64)

                    Picker("", selection: $gregMonth) {
                        ForEach(1...12, id: \.self) { m in
                            Text((lang == .fr ? Self.monthSymbolsFR : Self.monthSymbolsEN)[m - 1]).tag(m)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)

                    Stepper(value: $gregYear, in: 1792...3000) {
                        Text(String(gregYear))
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .onChange(of: gregMonth) { _ in
                    gregDay = min(gregDay, gregMaxDay)
                }
                .onChange(of: gregYear) { _ in
                    gregDay = min(gregDay, gregMaxDay)
                }

                gregorianToRepublicanResult
            }

            converterPanel(title: tr(lang, "Républicain → ancien style", "Republican → old style")) {
                HStack(spacing: 8) {
                    Picker("", selection: $repDay) {
                        ForEach(1...maxDay, id: \.self) { d in
                            Text("\(d)").tag(d)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 64)

                    Picker("", selection: $repMonth) {
                        ForEach(0..<12, id: \.self) { m in
                            Text(RepublicanData.months[m]).tag(m)
                        }
                        Text("Sans-culottides").tag(12)
                    }
                    .labelsHidden()
                    .frame(width: 150)

                    Stepper(value: $repYear, in: 1...3000) {
                        Text("An \(RepublicanCalendar.roman(repYear))")
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .onChange(of: repMonth) { _ in
                    repDay = min(repDay, maxDay)
                }
                .onChange(of: repYear) { _ in
                    repDay = min(repDay, maxDay)
                }

                republicanToGregorianResult
            }

            converterPanel(title: tr(lang, "Ancienne heure → décimale", "Old time → decimal")) {
                HStack(spacing: 8) {
                    Picker("", selection: $oldHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d", h)).tag(h)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)

                    Text("h")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Theme.faded)

                    Picker("", selection: $oldMinute) {
                        ForEach(0..<60, id: \.self) { m in
                            Text(String(format: "%02d", m)).tag(m)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)

                    Text("min")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Theme.faded)
                }

                timeResult(
                    String(format: "%d:%02d:%02d", decimalFromOld.0, decimalFromOld.1, decimalFromOld.2),
                    caption: tr(lang, "heure décimale", "decimal time")
                )
            }

            converterPanel(title: tr(lang, "Heure décimale → ancienne", "Decimal time → old")) {
                HStack(spacing: 8) {
                    Picker("", selection: $decHour) {
                        ForEach(0..<10, id: \.self) { h in
                            Text("\(h)").tag(h)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 64)

                    Text("h")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Theme.faded)

                    Picker("", selection: $decMinute) {
                        ForEach(0..<100, id: \.self) { m in
                            Text(String(format: "%02d", m)).tag(m)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)

                    Text("min")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Theme.faded)
                }

                timeResult(
                    String(format: "%02d:%02d:%02d", oldFromDecimal.0, oldFromDecimal.1, oldFromDecimal.2),
                    caption: tr(lang, "heure ancienne", "old-style time")
                )
            }
        }
    }

    // 24 h × 60 min map onto 10 h × 100 min × 100 s of the same day.
    private var decimalFromOld: (Int, Int, Int) {
        let total = Int((Double(oldHour * 3600 + oldMinute * 60) / 86400 * 100_000).rounded()) % 100_000
        return (total / 10_000, (total / 100) % 100, total % 100)
    }

    private var oldFromDecimal: (Int, Int, Int) {
        let seconds = Int((Double(decHour * 10_000 + decMinute * 100) / 100_000 * 86400).rounded()) % 86400
        return (seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }

    private func timeResult(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .serif).monospacedDigit())
                .foregroundStyle(Theme.blue)
            Text(caption)
                .font(.system(size: 12, design: .serif).italic())
                .foregroundStyle(Theme.faded)
        }
    }

    private func converterPanel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .kerning(1)
                .foregroundStyle(Theme.gold)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.gold.opacity(0.6), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var gregorianToRepublicanResult: some View {
        let rep = RepublicanCalendar.date(from: gregorianInput)
        if rep.year < 1 {
            Text(tr(lang,
                    "C'est avant la République ! Le calendrier commence le 22 septembre 1792.",
                    "That is before the Republic! The calendar starts on September 22, 1792."))
                .font(.system(size: 13, design: .serif).italic())
                .foregroundStyle(Theme.red)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                if rep.isComplementary {
                    Text("\(RepublicanData.complementaryDays[rep.day - 1]) · An \(RepublicanCalendar.roman(rep.year))")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.blue)
                    if lang == .en {
                        Text(RepublicanData.complementaryDaysEN[rep.day - 1])
                            .font(.system(size: 12, design: .serif).italic())
                            .foregroundStyle(Theme.red)
                    }
                } else {
                    Text("\(rep.decadeDayName) \(rep.day) \(RepublicanData.months[rep.month]) · An \(RepublicanCalendar.roman(rep.year))")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.blue)
                    if let rural = rep.ruralDayName {
                        Text(lang == .fr
                             ? "✿ \(rural)"
                             : "✿ \(RepublicanData.ruralDaysEN[rep.month * 30 + rep.day - 1]) · \(rural)")
                            .font(.system(size: 12, design: .serif).italic())
                            .foregroundStyle(Theme.red)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var republicanToGregorianResult: some View {
        if let date = RepublicanCalendar.gregorianDate(year: repYear, month: repMonth, day: repDay) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatter.string(from: date))
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.blue)
                if repMonth == 12 {
                    Text(lang == .fr
                         ? RepublicanData.complementaryDays[repDay - 1]
                         : RepublicanData.complementaryDaysEN[repDay - 1])
                        .font(.system(size: 12, design: .serif).italic())
                        .foregroundStyle(Theme.red)
                } else {
                    Text(lang == .fr
                         ? "✿ \(RepublicanData.ruralDays[repMonth * 30 + repDay - 1])"
                         : "✿ \(RepublicanData.ruralDaysEN[repMonth * 30 + repDay - 1]) · \(RepublicanData.ruralDays[repMonth * 30 + repDay - 1])")
                        .font(.system(size: 12, design: .serif).italic())
                        .foregroundStyle(Theme.red)
                }
            }
        }
    }
}

private struct ComplementaryPage: View {
    let lang: Language
    @State private var selectedDay: Int? = nil

    var body: some View {
        let rep = RepublicanCalendar.date(from: Date())

        VStack(alignment: .leading, spacing: 14) {
            PageTitle(
                "Sans-culottides",
                subtitle: tr(lang, "les jours complémentaires", "the complementary days")
            )

            Prose(tr(lang,
                """
                Douze mois de trente jours ne font que 360 jours. Les 5 jours \
                restants (6 les années sextiles) deviennent des fêtes nationales \
                en l'honneur des sans-culottes, les révolutionnaires du peuple. \
                Elles closent l'année entre la fin de Fructidor et le 1er \
                Vendémiaire.
                """,
                """
                Twelve months of thirty days only make 360 days. The 5 remaining \
                days (6 in leap years) became national festivals honoring the \
                sans-culottes, the working-class revolutionaries. They close the \
                year between the end of Fructidor and the 1st of Vendémiaire.
                """))

            VStack(spacing: 0) {
                ForEach(1...6, id: \.self) { day in
                    let isToday = rep.isComplementary && day == rep.day
                    Button {
                        selectedDay = day
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(day)")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .foregroundStyle(isToday ? .white : Theme.faded)
                                .frame(width: 22, height: 20)
                                .background(Circle().fill(isToday ? Theme.red : .clear))
                            Text(RepublicanData.complementaryDays[day - 1])
                                .font(.system(size: 13, weight: isToday ? .semibold : .regular, design: .serif))
                                .foregroundStyle(isToday ? Theme.red : Theme.ink)
                            Spacer()
                            Text(RepublicanData.complementaryDaysEN[day - 1])
                                .font(.system(size: 12, design: .serif).italic())
                                .foregroundStyle(Theme.faded)
                            if day == 6 {
                                Text(tr(lang, "années sextiles seulement", "leap years only"))
                                    .font(.system(size: 11, design: .serif))
                                    .foregroundStyle(Theme.red)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: Binding(
                        get: { selectedDay == day },
                        set: { if !$0 { selectedDay = nil } }
                    )) {
                        DayInfoPopover(lang: lang, rep: rep, month: 12, day: day)
                    }
                    .padding(.vertical, 5)
                    if day < 6 {
                        Divider()
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.gold.opacity(0.6), lineWidth: 1)
            )

            Prose(tr(lang,
                """
                La sixième, la Fête de la Révolution, n'arrive que les années \
                sextiles, quand l'année compte 366 jours.
                """,
                """
                The sixth one, the Festival of the Revolution, only happens in \
                leap years, when the year has 366 days.
                """))
        }
    }
}
