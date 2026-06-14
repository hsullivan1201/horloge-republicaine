import AVFoundation
import Foundation

// Rings a synthesized bell at each new decimal hour (every 2 h 24 of old
// time). At decimal noon (5:00) it plays the opening of La Marseillaise.
// Bells are generated in code: a fundamental with two decaying overtones,
// no sound files needed.
final class ChimeController {
    static let shared = ChimeController()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var timer: Timer?
    private var activePlays = 0

    private init() {}

    private var isSetUp = false

    func start() {
        UserDefaults.standard.register(defaults: ["chime": true])
        scheduleNext()
    }

    private func setUpIfNeeded() {
        guard !isSetUp else { return }
        isSetUp = true
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func preview() {
        play(notes: Self.marseillaise)
    }

    // MARK: - Scheduling

    private func scheduleNext() {
        let now = Date()
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: now)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let dayLength = dayEnd.timeIntervalSince(dayStart)
        let fraction = now.timeIntervalSince(dayStart) / dayLength

        let nextIndex = floor(fraction * 10) + 1
        let fireDate = dayStart.addingTimeInterval(nextIndex / 10 * dayLength + 0.05)

        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            // Wake-from-sleep delivers stale timers; stay silent if the
            // moment passed more than two minutes ago.
            if Date().timeIntervalSince(fireDate) < 120 {
                self?.ring()
            }
            self?.scheduleNext()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func ring() {
        guard UserDefaults.standard.bool(forKey: "chime") else { return }
        play(notes: Self.marseillaise)
    }

    // MARK: - Bell synthesis

    private struct Note {
        let freq: Double
        let start: Double
        let duration: Double
    }

    // "Allons enfants de la Patrie..." on bells, every decimal hour.
    private static let marseillaise = [
        Note(freq: 293.66, start: 0.00, duration: 0.40), // D4  Al-
        Note(freq: 293.66, start: 0.24, duration: 0.32), // D4  lons
        Note(freq: 293.66, start: 0.44, duration: 0.32), // D4  en-
        Note(freq: 392.00, start: 0.64, duration: 1.00), // G4  fants
        Note(freq: 392.00, start: 1.18, duration: 1.00), // G4  de
        Note(freq: 440.00, start: 1.72, duration: 1.00), // A4  la
        Note(freq: 440.00, start: 2.26, duration: 1.00), // A4  Pa-
        Note(freq: 587.33, start: 2.80, duration: 1.40), // D5  tri-
        Note(freq: 493.88, start: 3.60, duration: 0.80), // B4  i-
        Note(freq: 392.00, start: 4.04, duration: 1.60), // G4  e
    ]

    private func play(notes: [Note]) {
        setUpIfNeeded()
        guard let buffer = render(notes) else { return }
        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }
        activePlays += 1
        player.scheduleBuffer(buffer, at: nil) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard let self else { return }
                self.activePlays -= 1
                if self.activePlays <= 0 {
                    self.activePlays = 0
                    self.engine.pause()
                }
            }
        }
        player.play()
    }

    private func render(_ notes: [Note]) -> AVAudioPCMBuffer? {
        let total = notes.map { $0.start + $0.duration }.max()! + 0.3
        let frames = AVAudioFrameCount(total * sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames

        for note in notes {
            let startFrame = Int(note.start * sampleRate)
            let noteFrames = Int(note.duration * sampleRate)
            let w = 2.0 * Double.pi * note.freq / sampleRate
            for i in 0..<noteFrames {
                let frame = startFrame + i
                guard frame < Int(frames) else { break }
                let t = Double(i) / sampleRate
                let envelope = exp(-4.0 * t / note.duration)
                // Bell-ish timbre: fundamental plus two fading overtones.
                let value = sin(w * Double(i)) * 0.6
                    + sin(2.0 * w * Double(i)) * 0.25
                    + sin(3.0 * w * Double(i)) * 0.1
                samples[frame] += Float(value * envelope * 0.22)
            }
        }
        return buffer
    }
}
