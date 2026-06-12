import SwiftUI

// The lore browser: everything about the Republican calendar and decimal
// time, in French or English.
struct AlmanachView: View {
    enum Page: Hashable {
        case system
        case decade
        case month(Int)
        case complementary
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
                    }
                }
                .frame(maxWidth: 560, alignment: .leading)
                .padding(28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.parchment)
        }
        .frame(minWidth: 700, minHeight: 480)
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

private struct ComplementaryPage: View {
    let lang: Language

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
