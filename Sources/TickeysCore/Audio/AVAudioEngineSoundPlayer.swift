@preconcurrency
import AVFoundation
import Foundation

public final class AVAudioEngineSoundPlayer: SoundPlayer, @unchecked Sendable {
    public private(set) var loadedSoundCount: Int = 0
    public let voiceCount: Int
    public let idleStopInterval: TimeInterval
    public private(set) var volume: Float = 1.0
    public private(set) var pitch: Float = 1.0

    private let engine: AVAudioEngine
    private let playerQueue: DispatchQueue
    private var voices: [Voice]
    private var buffers: [AVAudioPCMBuffer] = []
    private var nextVoiceIndex = 0
    private var idleStopWorkItem: DispatchWorkItem?
    private let outputFormat: AVAudioFormat

    public init(
        voiceCount: Int = 2,
        idleStopInterval: TimeInterval = 1.0,
        engine: AVAudioEngine = AVAudioEngine()
    ) {
        self.playerQueue = DispatchQueue(label: "github.zjjfly.Tickeys-Swift.sound-player", qos: .userInitiated)
        self.voiceCount = max(1, voiceCount)
        self.idleStopInterval = max(0, idleStopInterval)
        self.engine = engine
        self.outputFormat = engine.outputNode.inputFormat(forBus: 0)
        self.voices = []

        for _ in 0..<self.voiceCount {
            let voice = Voice()
            voices.append(voice)
            engine.attach(voice.playerNode)
            engine.attach(voice.varispeedUnit)
            voice.connect(engine: engine, format: outputFormat, bypass: true)
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
                loadedBuffers.append(try Self.loadBuffer(from: file, targetFormat: outputFormat))
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
        let requiresPitchUnit = self.pitch != 1.0

        for voice in voices {
            voice.varispeedUnit.rate = self.pitch
            voice.connect(engine: engine, format: outputFormat, bypass: !requiresPitchUnit)
        }
    }

    @discardableResult
    public func play(index: Int) -> Bool {
        guard index >= 0, index < buffers.count else {
            return false
        }

        playerQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard self.startEngineIfNeeded() else {
                return
            }

            self.idleStopWorkItem?.cancel()
            let voice = self.voices[self.nextVoiceIndex]
            self.nextVoiceIndex = (self.nextVoiceIndex + 1) % self.voices.count

            voice.playerNode.stop()
            voice.playerNode.scheduleBuffer(self.buffers[index], at: nil, options: .interrupts)
            voice.playerNode.play()

            let stopWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else {
                    return
                }
                self.stopAllOnQueue()
            }
            self.idleStopWorkItem = stopWorkItem
            self.playerQueue.asyncAfter(deadline: .now() + self.idleStopInterval, execute: stopWorkItem)
        }

        return true
    }

    public func stopAll() {
        playerQueue.sync {
            stopAllOnQueue()
        }
    }

    private func startEngineIfNeeded() -> Bool {
        guard !engine.isRunning else {
            return true
        }

        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    private func stopAllOnQueue() {
        idleStopWorkItem?.cancel()
        idleStopWorkItem = nil
        for voice in voices {
            voice.playerNode.stop()
        }
        engine.stop()
    }

    private static func loadBuffer(from url: URL, targetFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url)
        } catch {
            throw SoundPlayerError.invalidAudioFile
        }

        let sourceFormat = file.processingFormat
        let frameCapacity = AVAudioFrameCount(file.length)
        guard let sourceBuffer = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: frameCapacity
        ) else {
            throw SoundPlayerError.invalidAudioFile
        }

        do {
            try file.read(into: sourceBuffer)
        } catch {
            throw SoundPlayerError.invalidAudioFile
        }

        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw SoundPlayerError.invalidAudioFile
        }

        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: AVAudioFrameCount(Double(sourceBuffer.frameLength) * targetFormat.sampleRate / sourceFormat.sampleRate) + 1
        ) else {
            throw SoundPlayerError.invalidAudioFile
        }

        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return sourceBuffer
        }

        var conversionError: NSError?
        let status = converter.convert(to: convertedBuffer, error: &conversionError, withInputFrom: inputBlock)

        switch status {
        case .haveData, .endOfStream:
            break
        default:
            throw conversionError ?? SoundPlayerError.invalidAudioFile
        }

        return convertedBuffer
    }
}

private final class Voice {
    let playerNode = AVAudioPlayerNode()
    let varispeedUnit = AVAudioUnitVarispeed()

    func connect(engine: AVAudioEngine, format: AVAudioFormat, bypass: Bool) {
        engine.disconnectNodeOutput(playerNode)
        engine.disconnectNodeOutput(varispeedUnit)

        if bypass {
            engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        } else {
            engine.connect(playerNode, to: varispeedUnit, format: format)
            engine.connect(varispeedUnit, to: engine.mainMixerNode, format: format)
        }
    }
}
