// Draws the app icon: Icon/AppIcon.icns for the Mac, and the full-bleed
// 1024 px PNG the iPhone app's asset catalog uses.
//
//   swift Icon/make-icon.swift                  build both (Cocarde)
//   swift Icon/make-icon.swift preview <dir>    write PNG previews of all variants
//
// Same vocabulary as the in-app dial: enamel face, gilt bezel, all ten
// numerals in Didot, a Breguet hour hand. The hands stand at 8.17, the
// decimal answer to a watch ad's 10:10.
import AppKit
import CoreText

enum Variant: String, CaseIterable {
    case cocarde, email, nuit
}

struct RGB {
    let r, g, b: CGFloat
    var a: CGFloat = 1
    var cg: CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }
    init(_ hex: UInt32, _ a: CGFloat = 1) {
        r = CGFloat((hex >> 16) & 0xff) / 255
        g = CGFloat((hex >> 8) & 0xff) / 255
        b = CGFloat(hex & 0xff) / 255
        self.a = a
    }
}

let navyTop = RGB(0x22336F), navyBottom = RGB(0x0C1233)
let parchTop = RGB(0xF7F0DF), parchBottom = RGB(0xE9DDBF)
let flagBlue = RGB(0x1F3A93), flagRed = RGB(0xC8202F), white = RGB(0xF6F2E8)
let enamel = RGB(0xFBF7EE), enamelEdge = RGB(0xEFE6D2)
let ink = RGB(0x1F2130), steel = RGB(0x1D3A8A), red = RGB(0xC8202F)
let goldLight = RGB(0xE8CB7A), goldDark = RGB(0x9C7A2E)
let nightFace = RGB(0x16204A), nightFaceEdge = RGB(0x0E1533), gilt = RGB(0xD9BA6A), pale = RGB(0xC9D4FF)

func angle(_ turns: CGFloat) -> CGFloat { .pi / 2 - turns * 2 * .pi }  // y-up, clockwise from 12
func point(_ c: CGPoint, _ a: CGFloat, _ r: CGFloat) -> CGPoint { CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r) }
func circle(_ c: CGPoint, _ r: CGFloat) -> CGRect { CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r) }

func linear(_ ctx: CGContext, _ top: RGB, _ bottom: RGB, in rect: CGRect) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [top.cg, bottom.cg] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
}

func radial(_ ctx: CGContext, _ inner: RGB, _ outer: RGB, center: CGPoint, radius: CGFloat) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [inner.cg, outer.cg] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: center.x - radius * 0.2, y: center.y + radius * 0.25), startRadius: 0,
                           endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
}

func text(_ ctx: CGContext, _ string: String, size: CGFloat, color: RGB, at p: CGPoint, bold: Bool = false) {
    let font = CTFontCreateWithName((bold ? "Didot-Bold" : "Didot") as CFString, size, nil)
    let attr = NSAttributedString(string: string, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color.cg,
    ])
    let line = CTLineCreateWithAttributedString(attr)
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    ctx.textPosition = CGPoint(x: p.x - bounds.midX, y: p.y - bounds.midY)
    CTLineDraw(line, ctx)
}

// Pleated cockade: concentric bands, each band made of alternating light
// and shaded wedges so it reads as folded ribbon.
func cockade(_ ctx: CGContext, center c: CGPoint, outer: CGFloat) {
    let bands: [(RGB, CGFloat)] = [(flagRed, outer), (white, outer * 0.86), (flagBlue, outer * 0.73)]
    let pleats = 48
    for (color, r) in bands {
        // Scalloped outer edge
        let path = CGMutablePath()
        for i in 0...pleats * 2 {
            let a = CGFloat(i) / CGFloat(pleats * 2) * 2 * .pi
            let rr = i % 2 == 0 ? r : r * 0.975
            let p = point(c, a, rr)
            i == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        ctx.addPath(path)
        ctx.setFillColor(color.cg)
        ctx.fillPath()
        // Shaded pleats
        for i in 0..<pleats where i % 2 == 0 {
            let a0 = CGFloat(i) / CGFloat(pleats) * 2 * .pi
            let a1 = CGFloat(i + 1) / CGFloat(pleats) * 2 * .pi
            let wedge = CGMutablePath()
            wedge.move(to: c)
            wedge.addArc(center: c, radius: r * 0.975, startAngle: a0, endAngle: a1, clockwise: false)
            wedge.closeSubpath()
            ctx.addPath(wedge)
            ctx.setFillColor(CGColor(gray: 0, alpha: 0.10))
            ctx.fillPath()
        }
    }
}

func bezel(_ ctx: CGContext, center c: CGPoint, radius r: CGFloat, width w: CGFloat) {
    // Gilt ring with a light-to-dark gradient, then fine inner and outer lines.
    ctx.saveGState()
    ctx.addEllipse(in: circle(c, r + w))
    ctx.addEllipse(in: circle(c, r))
    ctx.clip(using: .evenOdd)
    linear(ctx, goldLight, goldDark, in: circle(c, r + w))
    ctx.restoreGState()
    ctx.setStrokeColor(RGB(0x6E5420).cg)
    ctx.setLineWidth(w * 0.08)
    ctx.strokeEllipse(in: circle(c, r + w))
    ctx.strokeEllipse(in: circle(c, r))
}

struct DialStyle {
    let face: RGB, faceEdge: RGB, numerals: RGB, ticks: RGB, minorTicks: RGB, hourHand: RGB, minuteHand: RGB, hub: RGB
}

func dial(_ ctx: CGContext, center c: CGPoint, radius r: CGFloat, style s: DialStyle) {
    ctx.saveGState()
    ctx.addEllipse(in: circle(c, r))
    ctx.clip()
    radial(ctx, s.face, s.faceEdge, center: c, radius: r)
    ctx.restoreGState()

    // 100-tick decimal minute track
    for i in 0..<100 {
        let major = i % 10 == 0
        let a = angle(CGFloat(i) / 100)
        ctx.move(to: point(c, a, r * (major ? 0.84 : 0.91)))
        ctx.addLine(to: point(c, a, r * 0.97))
        ctx.setStrokeColor((major ? s.ticks : s.minorTicks).cg)
        ctx.setLineWidth(r * (major ? 0.022 : 0.006))
        ctx.setLineCap(.butt)
        ctx.strokePath()
    }

    // All ten numerals, 10 at the top
    for n in 1...10 {
        let p = point(c, angle(CGFloat(n) / 10), r * 0.68)
        text(ctx, "\(n)", size: r * (n == 10 ? 0.25 : 0.27), color: s.numerals, at: p)
    }

    // Hands at 8.17: hour hand toward 8, minute hand toward 1.7
    let hourTurns: CGFloat = 0.817, minuteTurns: CGFloat = 0.17
    func shaft(_ turns: CGFloat, _ length: CGFloat, _ width: CGFloat, _ color: RGB) {
        let a = angle(turns)
        ctx.move(to: point(c, a + .pi, length * 0.16))
        ctx.addLine(to: point(c, a, length))
        ctx.setStrokeColor(color.cg)
        ctx.setLineWidth(width)
        ctx.setLineCap(.round)
        ctx.strokePath()
    }
    func tip(_ turns: CGFloat, from: CGFloat, to: CGFloat, half: CGFloat, _ color: RGB) {
        let a = angle(turns)
        let base = point(c, a, from)
        let n = CGPoint(x: -sin(a) * half, y: cos(a) * half)
        ctx.move(to: CGPoint(x: base.x + n.x, y: base.y + n.y))
        ctx.addLine(to: point(c, a, to))
        ctx.addLine(to: CGPoint(x: base.x - n.x, y: base.y - n.y))
        ctx.closePath()
        ctx.setFillColor(color.cg)
        ctx.fillPath()
    }

    // Minute hand: slim leaf
    shaft(minuteTurns, r * 0.70, r * 0.035, s.minuteHand)
    tip(minuteTurns, from: r * 0.70, to: r * 0.84, half: r * 0.022, s.minuteHand)

    // Hour hand: Breguet, shaft + hollow pomme + point
    let ringAt = r * 0.42, ringR = r * 0.075
    let a = angle(hourTurns)
    shaft(hourTurns, ringAt - ringR, r * 0.05, s.hourHand)
    ctx.setStrokeColor(s.hourHand.cg)
    ctx.setLineWidth(r * 0.036)
    ctx.strokeEllipse(in: circle(point(c, a, ringAt), ringR))
    tip(hourTurns, from: ringAt + ringR * 0.9, to: r * 0.6, half: r * 0.03, s.hourHand)

    // Hub
    ctx.setFillColor(s.hourHand.cg)
    ctx.fillEllipse(in: circle(c, r * 0.07))
    ctx.setFillColor(s.hub.cg)
    ctx.fillEllipse(in: circle(c, r * 0.035))
}

// fullBleed: the iPhone version. iOS rounds the corners itself and rejects
// transparency, so the tile's contents fill an opaque square instead.
func render(_ variant: Variant, size: Int, fullBleed: Bool = false) -> CGImage {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: (fullBleed ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast).rawValue)!
    ctx.setShouldAntialias(true)

    // macOS tile: 824 pt rounded square on a 1024 canvas, with a soft shadow
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = fullBleed
        ? CGPath(rect: tile, transform: nil)
        : CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    if fullBleed {
        ctx.scaleBy(x: CGFloat(size) / 824, y: CGFloat(size) / 824)
        ctx.translateBy(x: -100, y: -100)
    } else {
        ctx.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: CGColor(gray: 0, alpha: 0.35))
        ctx.addPath(shape)
        ctx.setFillColor(CGColor(gray: 0.5, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()
    }

    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    let c = CGPoint(x: 512, y: 512)

    let cream = DialStyle(face: enamel, faceEdge: enamelEdge, numerals: ink, ticks: ink,
                          minorTicks: RGB(0x9C7A2E, 0.8), hourHand: steel, minuteHand: ink, hub: red)
    switch variant {
    case .cocarde:
        linear(ctx, navyTop, navyBottom, in: tile)
        cockade(ctx, center: c, outer: 372)
        bezel(ctx, center: c, radius: 236, width: 18)
        dial(ctx, center: c, radius: 236, style: cream)
    case .email:
        linear(ctx, parchTop, parchBottom, in: tile)
        // Thin tricolor rings just outside the bezel
        for (color, r) in [(flagRed, 372.0), (white, 360.0), (flagBlue, 348.0)] as [(RGB, CGFloat)] {
            ctx.setFillColor(color.cg)
            ctx.fillEllipse(in: circle(c, r))
        }
        bezel(ctx, center: c, radius: 312, width: 24)
        dial(ctx, center: c, radius: 312, style: cream)
    case .nuit:
        linear(ctx, navyTop, navyBottom, in: tile)
        for (color, r) in [(flagRed, 372.0), (white, 360.0), (flagBlue, 348.0)] as [(RGB, CGFloat)] {
            ctx.setFillColor(color.cg)
            ctx.fillEllipse(in: circle(c, r))
        }
        bezel(ctx, center: c, radius: 312, width: 24)
        dial(ctx, center: c, radius: 312, style: DialStyle(
            face: nightFace, faceEdge: nightFaceEdge, numerals: gilt, ticks: gilt,
            minorTicks: RGB(0xD9BA6A, 0.55), hourHand: pale, minuteHand: RGB(0xECE3CC), hub: red))
    }
    ctx.restoreGState()

    // Hairline edge
    if !fullBleed {
        ctx.addPath(shape)
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 0.15))
        ctx.setLineWidth(2)
        ctx.strokePath()
    }
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, _ path: String) throws {
    try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: path))
}

let args = CommandLine.arguments
if args.count > 2 && args[1] == "preview" {
    for v in Variant.allCases {
        try writePNG(render(v, size: 1024), "\(args[2])/icon-\(v.rawValue).png")
        for s in [128, 64, 32] {
            try writePNG(render(v, size: s), "\(args[2])/icon-\(v.rawValue)-\(s).png")
        }
    }
    print("Wrote previews to \(args[2])")
} else {
    let variant = Variant.cocarde
    let iconset = "Icon/AppIcon.iconset"
    let fm = FileManager.default
    try? fm.removeItem(atPath: iconset)
    try fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)
    for base in [16, 32, 128, 256, 512] {
        try writePNG(render(variant, size: base), "\(iconset)/icon_\(base)x\(base).png")
        try writePNG(render(variant, size: base * 2), "\(iconset)/icon_\(base)x\(base)@2x.png")
    }
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    task.arguments = ["-c", "icns", iconset, "-o", "Icon/AppIcon.icns"]
    try task.run()
    task.waitUntilExit()
    try? fm.removeItem(atPath: iconset)
    print(task.terminationStatus == 0 ? "Wrote Icon/AppIcon.icns (\(variant.rawValue))" : "iconutil failed")

    let ios = "Mobile/Assets.xcassets/AppIcon.appiconset/HorlogeAppIcon.png"
    try writePNG(render(variant, size: 1024, fullBleed: true), ios)
    print("Wrote \(ios)")
}
