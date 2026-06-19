import Foundation

public enum SoundPlayerError: Error, Equatable {
    case fileNotFound
    case invalidAudioFile
    case engineStartFailed
}

public protocol SoundPlayer: AnyObject {
    var loadedSoundCount: Int { get }
    var voiceCount: Int { get }
    var volume: Float { get }
    var pitch: Float { get }

    func load(files: [URL]) throws
    func setVolume(_ volume: Float)
    func setPitch(_ pitch: Float)
    @discardableResult
    func play(index: Int) -> Bool
    func stopAll()
}
