import AVFoundation
import Foundation

public final class AVAudioEngineSoundPlayer: SoundPlayer {
    public private(set) var loadedSoundCount: Int = 0
    public let voiceCount: Int
    public private(set) var volume: Float = 1.0
    public private(set) var pitch: Float = 1.0

    private let engine: AVAudioEngine
    private var voices: [Voice]
    private var buffers: [AVAudioPCMBuffer] = []
    private var nextVoiceIndex = 0

    public init(voiceCount: Int = 2, engine: AVAudioEngine = AVAudioEngine()) {
        self.voiceCount = max(1, voiceCount)
        self.engine = engine
        self.voices = []

        for _ in 0..<self.voiceCount {
            let voice = Voice()
            voices.append(voice)
            engine.attach(voice.playerNode)
            engine.attach(voice.pitchUnit)
            engine.connect(voice.playerNode, to: voice.pitchUnit, format: nil)
            engine.connect(voice.pitchUnit, to: engine.mainMixerNode, format: nil)
        }
    }

    deinit {
        stopAll()
        engine.stop()
    }

    public func load(files: [URL]) throws {
        stopAll()

        var loadedBuffers: [AVAudioPCMBuffer] = []
        for file in files {
            guard FileManager.default.fileExists(atPath: file.path) else {
                throw SoundPlayerError.fileNotFound
            }

            do {
                loadedBuffers.append(try Self.loadBuffer(from: file))
            } catch let error as SoundPlayerError {
                throw error
            } catch {
                throw SoundPlayerError.invalidAudioFile
            }
        }

        buffers = loadedBuffers
        loadedSoundCount = buffers.count
    }

    public func setVolume(_ volume: Float) {
        self.volume = min(max(volume, 0), 1)
        for voice in voices {
            voice.playerNode.volume = self.volume
        }
    }

    public func setPitch(_ pitch: Float) {
        self.pitch = max(pitch, 0.01)
        for voice in voices {
            voice.pitchUnit.rate = self.pitch
        }
    }

    @discardableResult
    public func play(index: Int) -> Bool {
        guard index >= 0, index < buffers.count else {
            return false
        }

        do {
            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            return false
        }

        let voice = voices[nextVoiceIndex]
        nextVoiceIndex = (nextVoiceIndex + 1) % voices.count

        voice.playerNode.stop()
        voice.playerNode.scheduleBuffer(buffers[index], at: nil, options: .interrupts)
        voice.playerNode.play()
        return true
    }

    public func stopAll() {
        for voice in voices {
            voice.playerNode.stop()
        }
    }

    private static func loadBuffer(from url: URL) throws -> AVAudioPCMBuffer {
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url)
        } catch {
            throw SoundPlayerError.invalidAudioFile
        }

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw SoundPlayerError.invalidAudioFile
        }

        do {
            try file.read(into: buffer)
        } catch {
            throw SoundPlayerError.invalidAudioFile
        }

        return buffer
    }
}

private final class Voice {
    let playerNode = AVAudioPlayerNode()
    let pitchUnit = AVAudioUnitTimePitch()
}
