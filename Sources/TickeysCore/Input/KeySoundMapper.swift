public struct KeySoundMapper {
    private let scheme: AudioScheme

    public init(scheme: AudioScheme) {
        self.scheme = scheme
    }

    public func soundIndex(forKeyCode keyCode: UInt8) -> Int? {
        if let mappedIndex = scheme.keyAudioMap[keyCode] {
            return validIndex(Int(mappedIndex))
        }

        guard scheme.nonUniqueCount > 0 else {
            return nil
        }

        return validIndex(Int(keyCode % scheme.nonUniqueCount))
    }

    private func validIndex(_ index: Int) -> Int? {
        guard index >= 0, index < scheme.files.count else {
            return nil
        }
        return index
    }
}
