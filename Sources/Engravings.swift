import SwiftUI
import AppKit
import CoreImage

//  Engravings — public-domain botanical/zoological plates for the rural days,
//  harvested from Wikimedia Commons (originally gathered in
//  PrairialEngravings.swift). Only Prairial is filled in so far; other months
//  return nil and the day popover simply shows no plate.
//
//  status: .verified       = species name is in the filename, match self-checks
//          .sourceVerified = right period source, plate number unconfirmed
//          .needsVerify     = right subject searched, filename lacks the species
//          .placeholder     = no clean plate found

enum EngravingStatus { case verified, sourceVerified, needsVerify, placeholder }

struct Plate {
    let day: Int; let fr: String; let en: String; let subject: String
    let collection: String; let commonsFile: String?; let credit: String
    let license: String; let sourceURL: String; let status: EngravingStatus

    // Wikimedia serves full plates at several MB. Its thumbnailer only accepts
    // an allowlist of widths (500 is one of them), so we rewrite the upload URL
    // into a 500px thumbnail: insert /thumb after /commons and append the
    // sized filename. Already-encoded characters carry over unchanged.
    var imageURL: URL? {
        guard commonsFile != nil, !sourceURL.isEmpty else { return nil }
        let prefix = "https://upload.wikimedia.org/wikipedia/commons/"
        guard sourceURL.hasPrefix(prefix) else { return URL(string: sourceURL) }
        let rest = sourceURL.dropFirst(prefix.count)
        guard let file = rest.split(separator: "/").last else { return URL(string: sourceURL) }
        return URL(string: "\(prefix)thumb/\(rest)/500px-\(file)")
    }
}

enum Engravings {
    // month is 0-based; Prairial is index 8.
    static func plate(month: Int, day: Int) -> Plate? {
        guard month == 8 else { return nil }
        return prairialPlates.first { $0.day == day }
    }
}

let prairialPlates: [Plate] = [
    Plate(day: 2, fr: "Hémérocalle", en: "day-lily", subject: "Hemerocallis",
          collection: "Besler, Hortus Eystettensis (1640)", commonsFile: "File:Hortus Eystettensis, 1640 (BHL 45339 076).jpg",
          credit: "Basilius Besler", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/2/25/Hortus_Eystettensis%2C_1640_%28BHL_45339_076%29_-_Classis_Verna_65.jpg", status: .sourceVerified),
    Plate(day: 3, fr: "Trèfle", en: "clover", subject: "Trifolium pratense",
          collection: "Sturm, Deutschlands Flora", commonsFile: "File:Trifolium pratense Sturm35.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/d/d0/Trifolium_pratense_Sturm35.jpg", status: .verified),
    Plate(day: 4, fr: "Angélique", en: "angelica", subject: "Angelica archangelica",
          collection: "Sturm, Deutschlands Flora", commonsFile: "File:Angelica archangelica Sturm12026.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/4/48/Angelica_archangelica_Sturm12026.jpg", status: .verified),
    Plate(day: 5, fr: "Canard", en: "duck", subject: "Anas",
          collection: "Naumann, Vögel Deutschlands", commonsFile: "File:Johann Andreas Naumann's ... Naturgeschichte der Vögel Deutschlands, nach einigen Erfahrungen entworfen (Taf. 300) (6059472788).jpg",
          credit: "Naumann, Naturgeschichte der Vögel Deutschlands", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/6/6d/Johann_Andreas_Naumann%27s_..._Naturgeschichte_der_V%C3%B6gel_Deutschlands%2C_nach_einigen_Erfahrungen_entworfen_%28Taf._300%29_%286059472788%29.jpg", status: .sourceVerified),
    Plate(day: 6, fr: "Mélisse", en: "lemon balm", subject: "Melissa officinalis",
          collection: "Sturm, Deutschlands Flora", commonsFile: "File:Melissa officinalis Sturm55.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/e/ea/Melissa_officinalis_Sturm55.jpg", status: .verified),
    Plate(day: 7, fr: "Fromental", en: "oat-grass", subject: "Arrhenatherum elatius",
          collection: "Naturgeschichte des Pflanzenreichs", commonsFile: "File:Naturgeschichte des Pflanzenreichs Tafel V.jpg",
          credit: "Jacob Sturm (?)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/5/53/Naturgeschichte_des_Pflanzenreichs_Tafel_V.jpg", status: .needsVerify),
    Plate(day: 8, fr: "Martagon", en: "martagon lily", subject: "Lilium",
          collection: "Besler, Hortus Eystettensis (1640)", commonsFile: "File:Hortus Eystettensis, 1640 (BHL 45339 097).jpg",
          credit: "Basilius Besler", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/d/df/Hortus_Eystettensis%2C_1640_%28BHL_45339_097%29_-_Classis_Verna_86.jpg", status: .sourceVerified),
    Plate(day: 9, fr: "Serpolet", en: "wild thyme", subject: "Thymus serpyllum",
          collection: "Sturm, Deutschlands Flora", commonsFile: "File:Thymus serpyllum Sturm57.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/7/71/Thymus_serpyllum_Sturm57.jpg", status: .verified),
    Plate(day: 10, fr: "Faux", en: "scythe", subject: "scythe",
          collection: "placeholder", commonsFile: nil,
          credit: "—", license: "",
          sourceURL: "", status: .placeholder),
    Plate(day: 11, fr: "Fraise", en: "strawberry", subject: "Fragaria",
          collection: "Besler, Hortus Eystettensis (1640)", commonsFile: "File:Hortus Eystettensis, 1640 (BHL 45339 127).jpg",
          credit: "Basilius Besler", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/7/70/Hortus_Eystettensis%2C_1640_%28BHL_45339_127%29_-_Classis_Verna_116.jpg", status: .verified),
    Plate(day: 12, fr: "Bétoine", en: "betony", subject: "Stachys officinalis",
          collection: "Naturgeschichte des Pflanzenreichs", commonsFile: "File:Naturgeschichte des Pflanzenreichs Tafel XXXI.jpg",
          credit: "Jacob Sturm (?)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/2/27/Naturgeschichte_des_Pflanzenreichs_Tafel_XXXI.jpg", status: .needsVerify),
    Plate(day: 13, fr: "Pois", en: "pea", subject: "Pisum sativum",
          collection: "Naturgeschichte des Pflanzenreichs", commonsFile: "File:Naturgeschichte des Pflanzenreichs Tafel XXXVII.jpg",
          credit: "Jacob Sturm (?)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/3/30/Naturgeschichte_des_Pflanzenreichs_Tafel_XXXVII.jpg", status: .needsVerify),
    Plate(day: 14, fr: "Acacia", en: "false acacia", subject: "Robinia pseudoacacia",
          collection: "Naturgeschichte des Pflanzenreichs", commonsFile: "File:Naturgeschichte des Pflanzenreichs Tafel XXXVII.jpg",
          credit: "Jacob Sturm (?)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/3/30/Naturgeschichte_des_Pflanzenreichs_Tafel_XXXVII.jpg", status: .needsVerify),
    Plate(day: 15, fr: "Caille", en: "quail", subject: "Coturnix",
          collection: "Naumann, Vögel Deutschlands", commonsFile: "File:Johann Andreas Naumann's ... Naturgeschichte der Vögel Deutschlands, nach einigen Erfahrungen entworfen (Taf. 166) (6058878909).jpg",
          credit: "Naumann, Naturgeschichte der Vögel Deutschlands", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/a/a7/Johann_Andreas_Naumann%27s_..._Naturgeschichte_der_V%C3%B6gel_Deutschlands%2C_nach_einigen_Erfahrungen_entworfen_%28Taf._166%29_%286058878909%29.jpg", status: .sourceVerified),
    Plate(day: 16, fr: "Œillet", en: "carnation", subject: "Dianthus caryophyllus",
          collection: "Besler, Hortus Eystettensis (1640)", commonsFile: "File:Hortus Eystettensis, 1640 (BHL 45339 332).jpg",
          credit: "Basilius Besler", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/4/41/Hortus_Eystettensis%2C_1640_%28BHL_45339_332%29_-_Classis_Aestiva_180.jpg", status: .verified),
    Plate(day: 17, fr: "Sureau", en: "elder", subject: "Sambucus",
          collection: "Besler, Hortus Eystettensis (1640)", commonsFile: "File:Hortus Eystettensis, 1640 (BHL 45339 021).jpg",
          credit: "Basilius Besler", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/9/9a/Hortus_Eystettensis%2C_1640_%28BHL_45339_021%29_-_Classis_Verna_10.jpg", status: .sourceVerified),
    Plate(day: 18, fr: "Pavot", en: "poppy", subject: "Papaver",
          collection: "Besler, Hortus Eystettensis (1640)", commonsFile: "File:Hortus Eystettensis, 1640 (BHL 45339 309).jpg",
          credit: "Basilius Besler", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/b/b6/Hortus_Eystettensis%2C_1640_%28BHL_45339_309%29_-_Classis_Aestiva_157.jpg", status: .verified),
    Plate(day: 19, fr: "Tilleul", en: "linden", subject: "Tilia",
          collection: "Sturm, Deutschlands Flora", commonsFile: "File:Tilia platyphyllos Sturm61.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/e/e0/Tilia_platyphyllos_Sturm61.jpg", status: .verified),
    Plate(day: 20, fr: "Fourche", en: "pitchfork", subject: "fork",
          collection: "Diderot, Encyclopédie (planches)", commonsFile: "File:Encyclopedie Planches volume 4 (page 51 crop).jpg",
          credit: "Diderot et d'Alembert", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/8/8c/Encyclopedie_Planches_volume_4_%28page_51_crop%29.jpg", status: .sourceVerified),
    Plate(day: 21, fr: "Barbeau", en: "cornflower", subject: "Centaurea cyanus",
          collection: "Sturm, Deutschlands Flora", commonsFile: "File:Centaurea cyanus Sturm26.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/b/b1/Centaurea_cyanus_Sturm26.jpg", status: .verified),
    Plate(day: 22, fr: "Camomille", en: "chamomile", subject: "Matricaria chamomilla",
          collection: "Naturgeschichte des Pflanzenreichs", commonsFile: "File:Naturgeschichte des Pflanzenreichs Tafel XLIII.jpg",
          credit: "Jacob Sturm (?)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/a/a8/Naturgeschichte_des_Pflanzenreichs_Tafel_XLIII.jpg", status: .needsVerify),
    Plate(day: 23, fr: "Chèvrefeuille", en: "honeysuckle", subject: "Lonicera caprifolium",
          collection: "various", commonsFile: "File:Lonicera caprifolium.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/6/6a/Lonicera_caprifolium.jpg", status: .verified),
    Plate(day: 24, fr: "Caille-lait", en: "bedstraw", subject: "Galium verum",
          collection: "Sturm, Deutschlands Flora", commonsFile: "File:Galium spp Sturm50.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/a/a0/Galium_spp_Sturm50.jpg", status: .verified),
    Plate(day: 25, fr: "Tanche", en: "tench", subject: "Tinca tinca",
          collection: "Bloch, Fische Deutschlands", commonsFile: "File:D. Marcus Elieser Bloch's, ausübenden Arztes zu Berlin ... Ökonomische Naturgeschichte der Fische Deutschlands (Tafel 14) (6032435277).jpg",
          credit: "Marcus Elieser Bloch, Naturgeschichte der Fische", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/9/90/D._Marcus_Elieser_Bloch%27s%2C_aus%C3%BCbenden_Arztes_zu_Berlin_..._%C3%96konomische_Naturgeschichte_der_Fische_Deutschlands_%28Tafel_14%29_%286032435277%29.jpg", status: .sourceVerified),
    Plate(day: 26, fr: "Jasmin", en: "jasmine", subject: "Jasminum officinale",
          collection: "Curtis, Botanical Magazine", commonsFile: "File:The Botanical Magazine, Plate 31 (Volume 1, 1787).png",
          credit: "James Sowerby / William Curtis", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/2/21/The_Botanical_Magazine%2C_Plate_31_%28Volume_1%2C_1787%29.png", status: .needsVerify),
    Plate(day: 27, fr: "Verveine", en: "verbena", subject: "Verbena officinalis",
          collection: "Sturm, Deutschlands Flora", commonsFile: "File:Verbena officinalis Sturm22.jpg",
          credit: "Johann Georg Sturm (Painter: Jacob Sturm)", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/6/68/Verbena_officinalis_Sturm22.jpg", status: .verified),
    Plate(day: 28, fr: "Thym", en: "thyme", subject: "Thymus vulgaris",
          collection: "Köhler, Medizinal-Pflanzen", commonsFile: "File:Thymus vulgaris - Köhler–s Medizinal-Pflanzen-271.jpg",
          credit: "Walther Otto Müller", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/1/12/Thymus_vulgaris_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-271.jpg", status: .verified),
    Plate(day: 29, fr: "Pivoine", en: "peony", subject: "Paeonia officinalis",
          collection: "Besler, Hortus Eystettensis (1613)", commonsFile: "File:Hortus Eystettensis, 1613 (KU 2894-1 346) -Verna,6,15.jpg",
          credit: "Basilius Besler / Wolfgang Kilian", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/1/17/Hortus_Eystettensis%2C_1613_%28KU_2894-1_346%29_-Verna%2C6%2C15.jpg", status: .needsVerify),
    Plate(day: 30, fr: "Chariot", en: "handcart", subject: "cart",
          collection: "Diderot, Encyclopédie (planches)", commonsFile: "File:Encyclopedie volume 2b-007.png",
          credit: "Diderot et d'Alembert", license: "Public domain",
          sourceURL: "https://upload.wikimedia.org/wikipedia/commons/6/6d/Encyclopedie_volume_2b-007.png", status: .sourceVerified),
]

// MARK: - Networking

enum EngravingNetwork {
    // Wikimedia asks third-party apps to send a descriptive User-Agent, which
    // AsyncImage can't set; a small caching session does it and keeps plates
    // around between popovers.
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "HorlogeRepublicaine/1.0 (https://lostinthehaze.net; decimal time app)"
        ]
        config.urlCache = URLCache(memoryCapacity: 16 << 20, diskCapacity: 128 << 20, diskPath: "horloge-engravings")
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    // Decode and strip color so the plate reads as a grey engraving. Not on
    // the main actor, so the detached task does this work off the UI thread.
    static func grayscale(_ data: Data) -> NSImage? {
        guard let source = CIImage(data: data) else {
            return NSImage(data: data)  // fall back to color rather than nothing
        }
        let mono = source.applyingFilter("CIColorControls",
                                         parameters: [kCIInputSaturationKey: 0.0,
                                                      kCIInputContrastKey: 1.05])
        let context = CIContext()
        guard let cg = context.createCGImage(mono, from: mono.extent) else {
            return NSImage(data: data)
        }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }
}

// MARK: - View

struct EngravingView: View {
    let plate: Plate
    let lang: Language

    @State private var image: NSImage?
    @State private var failed = false

    var body: some View {
        VStack(spacing: 4) {
            if let url = plate.imageURL {
                content(url: url)
                caption
            } else {
                placeholder
            }
        }
    }

    @ViewBuilder
    private func content(url: URL) -> some View {
        ZStack {
            if let image {
                let fit = Self.fittedSize(image.size, maxW: 240, maxH: 270)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fit.width, height: fit.height)
                    .overlay(Rectangle().stroke(Theme.ink.opacity(0.3), lineWidth: 1))
            } else if failed {
                note(tr(lang, "gravure indisponible", "engraving unavailable"))
                    .frame(width: 240, height: 120)
            } else {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 240, height: 120)
            }
        }
        .task(id: url) {
            image = nil
            failed = false
            do {
                let (data, _) = try await EngravingNetwork.session.data(from: url)
                // Desaturate off the main actor; these plates read better as
                // grey sketches than in their faded period color.
                let gray = await Task.detached { EngravingNetwork.grayscale(data) }.value
                if let gray { image = gray } else { failed = true }
            } catch {
                failed = true
            }
        }
    }

    private var caption: some View {
        VStack(spacing: 1) {
            Text(plate.credit)
                .font(.system(size: 9, design: .serif).italic())
                .foregroundStyle(Theme.faded)
                .multilineTextAlignment(.center)
            Text("\(plate.collection) · " + tr(lang, "Wikimedia Commons, domaine public", "Wikimedia Commons, public domain")
                 + (plate.status == .needsVerify ? " · " + tr(lang, "à vérifier", "unverified") : ""))
                .font(.system(size: 8, design: .serif))
                .foregroundStyle(Theme.faded.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 240)
    }

    private var placeholder: some View {
        VStack(spacing: 4) {
            Text("✦").font(.system(size: 20)).foregroundStyle(Theme.gold.opacity(0.6))
            Text(tr(lang, "gravure à venir", "engraving to come"))
                .font(.system(size: 10, design: .serif).italic())
                .foregroundStyle(Theme.faded)
        }
        .frame(width: 240, height: 86)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.3)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.gold.opacity(0.4), lineWidth: 1))
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, design: .serif).italic())
            .foregroundStyle(Theme.faded)
    }

    // The frame hugs the plate's own proportions so there are no white bars
    // beside portrait images.
    static func fittedSize(_ s: CGSize, maxW: CGFloat, maxH: CGFloat) -> CGSize {
        guard s.width > 0, s.height > 0 else { return CGSize(width: maxW, height: maxH) }
        let aspect = s.width / s.height
        var w = maxH * aspect, h = maxH
        if w > maxW { w = maxW; h = maxW / aspect }
        return CGSize(width: w, height: h)
    }
}
