import SwiftUI

// Shared by the app and the widget extension.
enum Theme {
    static let parchment = Color(red: 0.957, green: 0.925, blue: 0.855)
    static let ink = Color(red: 0.12, green: 0.13, blue: 0.19)
    static let blue = Color(red: 0.0, green: 0.14, blue: 0.58)
    static let red = Color(red: 0.80, green: 0.11, blue: 0.17)
    static let gold = Color(red: 0.65, green: 0.53, blue: 0.20)
    static let faded = Color(red: 0.45, green: 0.42, blue: 0.36)
}

// A 10-hour dial, like the decimal watch faces of the 1790s. The hour hand
// makes one revolution per day.
struct DecimalClockFace: View {
    let dayFraction: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4
            let compact = radius < 70

            let rim = Path(ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            ))
            context.fill(rim, with: .color(.white.opacity(0.5)))
            context.stroke(rim, with: .color(Theme.ink), lineWidth: compact ? 2 : 3)

            for tick in 0..<100 {
                let isMajor = tick % 10 == 0
                if compact && !isMajor { continue }
                let angle = Double(tick) / 100 * 2 * .pi - .pi / 2
                var path = Path()
                path.move(to: point(center, angle, radius - (isMajor ? (compact ? 8 : 11) : 6)))
                path.addLine(to: point(center, angle, radius - 2))
                context.stroke(path, with: .color(Theme.ink), lineWidth: isMajor ? (compact ? 1.5 : 2) : 0.7)
            }

            for numeral in 1...10 {
                let angle = Double(numeral) / 10 * 2 * .pi - .pi / 2
                context.draw(
                    Text("\(numeral)")
                        .font(.system(size: compact ? 11 : 15, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink),
                    at: point(center, angle, radius - (compact ? 17 : 24))
                )
            }

            let hourTurns = dayFraction
            let minuteTurns = (dayFraction * 10).truncatingRemainder(dividingBy: 1)
            let secondTurns = (dayFraction * 1000).truncatingRemainder(dividingBy: 1)

            drawHand(context, center, turns: hourTurns, length: radius * 0.45, width: compact ? 3 : 4, color: Theme.blue)
            drawHand(context, center, turns: minuteTurns, length: radius * 0.66, width: compact ? 2 : 2.5, color: Theme.ink)
            if !compact {
                drawHand(context, center, turns: secondTurns, length: radius * 0.74, width: 1, color: Theme.red)
            }

            let hubSize: Double = compact ? 6 : 8
            let hub = Path(ellipseIn: CGRect(
                x: center.x - hubSize / 2, y: center.y - hubSize / 2,
                width: hubSize, height: hubSize
            ))
            context.fill(hub, with: .color(Theme.red))
        }
    }

    private func drawHand(_ context: GraphicsContext, _ center: CGPoint, turns: Double, length: Double, width: Double, color: Color) {
        let angle = turns * 2 * .pi - .pi / 2
        var path = Path()
        path.move(to: point(center, angle + .pi, length * 0.15))
        path.addLine(to: point(center, angle, length))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func point(_ center: CGPoint, _ angle: Double, _ radius: Double) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}
