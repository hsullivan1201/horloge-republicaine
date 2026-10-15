import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// Shared by the app and the widget extension.

// MARK: - Settings shared with the widget

enum AppGroup {
    // The app and widget share settings through an app group, so the widget
    // follows the app's language and appearance. The group ID comes from
    // Info.plist (build.sh writes the team-prefixed one on macOS). Without
    // it, settings stay in the app's own defaults and the widget falls back
    // to the system language and appearance.
    static let defaults: UserDefaults = {
        if let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String,
           !id.isEmpty,
           let shared = UserDefaults(suiteName: id) {
            return shared
        }
        return .standard
    }()

    // Settings used to live in the app's standard defaults.
    static func migrate() {
        guard defaults !== UserDefaults.standard else { return }
        for key in ["language", "chime"] where defaults.object(forKey: key) == nil {
            if let value = UserDefaults.standard.object(forKey: key) {
                defaults.set(value, forKey: key)
            }
        }
    }
}

enum Appearance: String, CaseIterable {
    case auto, jour, nuit

    var colorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .jour: return .light
        case .nuit: return .dark
        }
    }

    func label(_ lang: Language) -> String {
        switch self {
        case .auto: return "Auto"
        case .jour: return tr(lang, "Jour", "Day")
        case .nuit: return tr(lang, "Nuit", "Night")
        }
    }
}

// MARK: - Palettes

struct RGB {
    let r: Double, g: Double, b: Double
    var a: Double = 1

    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    init(hex: UInt32, _ a: Double = 1) {
        self.init(Double((hex >> 16) & 0xff) / 255,
                  Double((hex >> 8) & 0xff) / 255,
                  Double(hex & 0xff) / 255, a)
    }

    var color: Color { Color(red: r, green: g, blue: b, opacity: a) }
}

// Jour is parchment and iron-gall ink. Nuit is the same almanac by
// candlelight: ink-blue paper, gilt, and a paler steel blue.
struct Palette {
    let parchment: RGB  // background
    let ink: RGB        // text
    let blue: RGB
    let red: RGB
    let gold: RGB
    let faded: RGB      // secondary text
    let face: RGB       // dial enamel
    let rim: RGB        // dial rim
    let hand: RGB       // blued-steel hour hand
    let cell: RGB       // light fill for buttons and cells
    let rest: RGB       // décadi tint

    static let jour = Palette(
        parchment: RGB(0.957, 0.925, 0.855),
        ink: RGB(0.12, 0.13, 0.19),
        blue: RGB(0.0, 0.14, 0.58),
        red: RGB(0.80, 0.11, 0.17),
        gold: RGB(0.65, 0.53, 0.20),
        faded: RGB(0.45, 0.42, 0.36),
        face: RGB(hex: 0xFBF7EE),
        rim: RGB(0.12, 0.13, 0.19),
        hand: RGB(hex: 0x1D3A8A),
        cell: RGB(1, 1, 1, 0.5),
        rest: RGB(0.0, 0.14, 0.58, 0.07)
    )

    static let nuit = Palette(
        parchment: RGB(hex: 0x0F1630),
        ink: RGB(hex: 0xECE3CC),
        blue: RGB(hex: 0x9FB3FF),
        red: RGB(hex: 0xE8505C),
        gold: RGB(hex: 0xC9A961),
        faded: RGB(hex: 0x9B97A6),
        face: RGB(hex: 0x141D3D),
        rim: RGB(hex: 0xC9A961),
        hand: RGB(hex: 0x9FB3FF),
        cell: RGB(1, 1, 1, 0.06),
        rest: RGB(hex: 0x9FB3FF, 0.11)
    )

    static func `for`(_ scheme: ColorScheme) -> Palette {
        scheme == .dark ? .nuit : .jour
    }
}

enum Theme {
    static let parchment = adaptive(\.parchment)
    static let ink = adaptive(\.ink)
    static let blue = adaptive(\.blue)
    static let red = adaptive(\.red)
    static let gold = adaptive(\.gold)
    static let faded = adaptive(\.faded)
    static let cell = adaptive(\.cell)
    static let rest = adaptive(\.rest)

    // The flag keeps its real colors in both themes.
    static let flagBlue = Color(red: 0.0, green: 0.14, blue: 0.58)
    static let flagRed = Color(red: 0.80, green: 0.11, blue: 0.17)

    // Resolves against the view's appearance, so one name works in Jour and
    // Nuit, including in the menu bar panel and the widget.
    private static func adaptive(_ key: KeyPath<Palette, RGB>) -> Color {
        let light = Palette.jour[keyPath: key]
        let dark = Palette.nuit[keyPath: key]
#if os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let c = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: c.a)
        })
#else
        return Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.r, green: c.g, blue: c.b, alpha: c.a)
        })
#endif
    }
}

// MARK: - Type

// Didot was cut in Paris in the 1780s and 90s, the years of the calendar
// itself, and ships with both macOS and iOS. Used for display sizes; small
// text stays in the system serif, where Didot's hairlines get too thin.
extension Font {
    static func didot(_ size: CGFloat, bold: Bool = false, italic: Bool = false) -> Font {
        .custom(bold ? "Didot-Bold" : italic ? "Didot-Italic" : "Didot", size: size)
    }
}

// Didot's figures are proportional, so ticking digits would shuffle
// sideways. Each character gets a fixed cell instead.
struct DidotTime: View {
    let text: String
    let size: CGFloat
    var color: Color = Theme.ink

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, char in
                Text(String(char))
                    .font(.didot(size))
                    .frame(width: char.isNumber ? size * 0.58 : size * 0.3)
            }
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

// MARK: - Ticking

// Publishes the time at each decimal-second boundary (or every `unit`
// decimal seconds), measured from local midnight, so displayed seconds never
// skip or repeat. Each tick reschedules itself, which also keeps it correct
// after sleep and on 23 or 25 hour DST days.
final class DecimalTicker: ObservableObject {
    @Published private(set) var now = Date()
    private let unit: Double
    private var timer: Timer?

    init(every unit: Double = 1) {
        self.unit = unit
        schedule()
    }

    deinit {
        timer?.invalidate()
    }

    private func schedule() {
        let calendar = RepublicanCalendar.localGregorianCalendar
        let current = Date()
        let start = calendar.startOfDay(for: current)
        let length = calendar.date(byAdding: .day, value: 1, to: start)!.timeIntervalSince(start)
        let step = length / 100_000 * unit
        let index = floor(current.timeIntervalSince(start) / step) + 1
        let next = start.addingTimeInterval(index * step + 0.005)

        let timer = Timer(fire: next, interval: 0, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.now = Date()
            self.schedule()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}

// MARK: - Dial

// A 10-hour enamel dial, like the decimal clocks of the 1790s. The hour hand
// makes one revolution per day, so a 24-hour ring inside the 10-hour one
// reads off the same hand, as on the period clocks that showed both.
struct DecimalClockFace: View {
    enum Style {
        case full       // inner 24 h ring, all ticks, second hand
        case compact    // widget sizes: hours and minutes only
        case accessory  // lock screen: monochrome, no numerals
    }

    let time: DecimalTime
    var style: Style = .full
    // For widgets that iOS renders tinted or clear: everything in white at
    // varying opacity, no filled face. A filled face would turn into a solid
    // white disc there and swallow the numerals and hands.
    var monochrome = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 1
        // Geometry is laid out on a 147-unit radius and scaled to fit.
        let s = radius / 147
        let p = Palette.for(scheme)
        let accessory = style == .accessory
        let mono = accessory || monochrome
        let ink = mono ? Color.white : p.ink.color
        let gold = mono ? Color.white.opacity(0.55) : p.gold.color

        func pt(_ angle: Double, _ r: Double) -> CGPoint {
            CGPoint(x: center.x + cos(angle) * r * s, y: center.y + sin(angle) * r * s)
        }
        func circle(_ r: Double) -> Path {
            Path(ellipseIn: CGRect(x: center.x - r * s, y: center.y - r * s, width: 2 * r * s, height: 2 * r * s))
        }
        func angle(_ turns: Double) -> Double { turns * 2 * .pi - .pi / 2 }

        // Face and rims
        if accessory {
            context.stroke(circle(140), with: .color(.white.opacity(0.45)), lineWidth: 7 * s)
        } else if monochrome {
            context.fill(circle(147), with: .color(.white.opacity(0.08)))
            context.stroke(circle(146), with: .color(.white.opacity(0.9)), lineWidth: 3 * s)
        } else {
            context.fill(circle(147), with: .radialGradient(
                Gradient(colors: [p.face.color, p.face.color.opacity(scheme == .dark ? 1 : 0.82)]),
                center: CGPoint(x: center.x - radius * 0.12, y: center.y - radius * 0.2),
                startRadius: 0, endRadius: radius * 1.1))
            context.stroke(circle(147), with: .color(p.rim.color), lineWidth: 1.6 * s)
            context.stroke(circle(141), with: .color(p.rim.color), lineWidth: 0.7 * s)
        }

        // Decimal minute track
        if style == .full {
            context.stroke(circle(133), with: .color(gold), lineWidth: 0.6 * s)
            context.stroke(circle(125), with: .color(gold), lineWidth: 0.6 * s)
        }
        for tick in 0..<100 {
            let major = tick % 10 == 0
            if style != .full && !major { continue }
            let a = angle(Double(tick) / 100)
            var path = Path()
            switch style {
            case .full:
                path.move(to: pt(a, major ? 121 : 125))
                path.addLine(to: pt(a, 133))
                let width = major ? 2.2 : tick % 5 == 0 ? 1.0 : 0.6
                context.stroke(path, with: .color(major ? ink : gold), lineWidth: width * s)
            case .compact:
                path.move(to: pt(a, 124))
                path.addLine(to: pt(a, 138))
                context.stroke(path, with: .color(ink), lineWidth: 3.5 * s)
            case .accessory:
                path.move(to: pt(a, 112))
                path.addLine(to: pt(a, 128))
                context.stroke(path, with: .color(.white), lineWidth: 9 * s)
            }
        }

        // Numerals
        if !accessory {
            let numeralSize = style == .full ? 27 * s : 34 * s
            let numeralRadius: Double = style == .full ? 102 : 98
            for n in 1...10 {
                context.draw(
                    Text("\(n)").font(.didot(numeralSize)).foregroundStyle(ink),
                    at: pt(angle(Double(n) / 10), numeralRadius)
                )
            }
        }

        // Inner 24-hour ring
        if style == .full {
            var ring = circle(50)
            ring = ring.strokedPath(StrokeStyle(lineWidth: 0.6 * s, dash: [1 * s, 3 * s]))
            context.fill(ring, with: .color(gold))
            for hour in 1...24 {
                let position = pt(angle(Double(hour) / 24), 59)
                if hour % 2 == 0 {
                    context.draw(
                        Text("\(hour)").font(.didot(10.5 * s, italic: true)).foregroundStyle(p.red.color),
                        at: position
                    )
                } else {
                    let dot = Path(ellipseIn: CGRect(x: position.x - 1.1 * s, y: position.y - 1.1 * s, width: 2.2 * s, height: 2.2 * s))
                    context.fill(dot, with: .color(p.red.color))
                }
            }
        }

        // Hands
        let hourColor = mono ? Color.white : p.hand.color
        let minuteColor = mono ? Color.white.opacity(0.8) : ink
        let minuteTurns = (time.dayFraction * 10).truncatingRemainder(dividingBy: 1)

        // Breguet hour hand: shaft, hollow "pomme" near the tip, short point.
        func breguet(turns: Double, length: Double, width: Double, ringAt: Double, ringRadius: Double, color: Color) {
            let a = angle(turns)
            let ringCenter = length * ringAt
            var shaft = Path()
            shaft.move(to: pt(a + .pi, length * 0.14))
            shaft.addLine(to: pt(a, ringCenter - ringRadius))
            context.stroke(shaft, with: .color(color), style: StrokeStyle(lineWidth: width * s, lineCap: .round))

            let c = pt(a, ringCenter)
            let ring = Path(ellipseIn: CGRect(x: c.x - ringRadius * s, y: c.y - ringRadius * s, width: 2 * ringRadius * s, height: 2 * ringRadius * s))
            context.stroke(ring, with: .color(color), lineWidth: width * 0.8 * s)

            let spread = width * 0.9 / (ringCenter + ringRadius)
            var tip = Path()
            tip.move(to: pt(a + spread, ringCenter + ringRadius))
            tip.addLine(to: pt(a, length))
            tip.addLine(to: pt(a - spread, ringCenter + ringRadius))
            tip.closeSubpath()
            context.fill(tip, with: .color(color))
        }

        // Slim leaf minute hand.
        func leaf(turns: Double, length: Double, width: Double, color: Color) {
            let a = angle(turns)
            var shaft = Path()
            shaft.move(to: pt(a + .pi, length * 0.14))
            shaft.addLine(to: pt(a, length * 0.88))
            context.stroke(shaft, with: .color(color), style: StrokeStyle(lineWidth: width * s, lineCap: .round))
            let spread = width * 0.7 / (length * 0.88)
            var tip = Path()
            tip.move(to: pt(a + spread, length * 0.88))
            tip.addLine(to: pt(a, length))
            tip.addLine(to: pt(a - spread, length * 0.88))
            tip.closeSubpath()
            context.fill(tip, with: .color(color))
        }

        switch style {
        case .full:
            breguet(turns: time.dayFraction, length: 88, width: 3.4, ringAt: 0.82, ringRadius: 7.5, color: hourColor)
            leaf(turns: minuteTurns, length: 120, width: 2.4, color: minuteColor)
            // The second hand steps once per decimal second, one tick of the
            // 100-tick track each time.
            let a = angle(Double(time.seconds) / 100)
            var second = Path()
            second.move(to: pt(a + .pi, 30))
            second.addLine(to: pt(a, 128))
            context.stroke(second, with: .color(p.red.color), lineWidth: 1 * s)
            let weight = pt(a + .pi, 24)
            context.fill(Path(ellipseIn: CGRect(x: weight.x - 4 * s, y: weight.y - 4 * s, width: 8 * s, height: 8 * s)),
                         with: .color(p.red.color))
        case .compact:
            breguet(turns: time.dayFraction, length: 80, width: 7, ringAt: 0.7, ringRadius: 11, color: hourColor)
            leaf(turns: minuteTurns, length: 114, width: 4.5, color: minuteColor)
        case .accessory:
            breguet(turns: time.dayFraction, length: 78, width: 12, ringAt: 0.66, ringRadius: 14, color: hourColor)
            leaf(turns: minuteTurns, length: 108, width: 8, color: minuteColor)
        }

        // Hub
        let hub: Double = style == .full ? 5 : 10
        context.fill(circle(hub), with: .color(hourColor))
        context.fill(circle(hub * 0.35), with: .color(mono ? .black : p.red.color))
    }
}

// Real flag colors in both themes.
struct TricolorBar: View {
    var height: CGFloat = 6

    var body: some View {
        HStack(spacing: 0) {
            Theme.flagBlue
            Color.white
            Theme.flagRed
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
