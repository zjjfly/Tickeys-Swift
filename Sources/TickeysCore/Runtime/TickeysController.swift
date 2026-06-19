import Foundation

public enum TickeysControllerError: Error, Equatable {
    case emptySchemeList
    case unknownScheme(String)
}

public final class TickeysController {
    public private(set) var currentPreference: UserPreference
    public var availableSchemes: [AudioScheme] { schemes }
    public private(set) var isMuted = false
    public private(set) var activeAppName: String?
    public var isListening: Bool { keyboardMonitor.isRunning }

    private let schemes: [AudioScheme]
    private let resourceBaseURL: URL
    private let preferenceStore: PreferenceStore
    private let soundPlayer: SoundPlayer
    private let keyboardMonitor: KeyboardMonitoring
    private let onSettingsRequested: () -> Void

    private var mapper: KeySoundMapper
    private var throttler = RepeatedKeyThrottler()
    private var sequenceDetector = KeySequenceDetector()

    public init(
        schemes: [AudioScheme],
        resourceBaseURL: URL,
        preferenceStore: PreferenceStore,
        soundPlayer: SoundPlayer,
        keyboardMonitor: KeyboardMonitoring,
        onSettingsRequested: @escaping () -> Void = {}
    ) {
        self.schemes = schemes
        self.resourceBaseURL = resourceBaseURL
        self.preferenceStore = preferenceStore
        self.soundPlayer = soundPlayer
        self.keyboardMonitor = keyboardMonitor
        self.onSettingsRequested = onSettingsRequested

        let preference = preferenceStore.load(availableSchemes: schemes)
        self.currentPreference = preference
        let initialScheme = schemes.first { $0.name == preference.scheme } ?? schemes.first
        self.mapper = KeySoundMapper(scheme: initialScheme ?? AudioScheme(
            name: "",
            displayName: "",
            files: [],
            nonUniqueCount: 0,
            keyAudioMap: [:]
        ))
    }

    public func start() throws {
        guard !schemes.isEmpty else {
            throw TickeysControllerError.emptySchemeList
        }

        try loadCurrentScheme()
        soundPlayer.setVolume(currentPreference.volume)
        soundPlayer.setPitch(currentPreference.pitch)

        try keyboardMonitor.start { [weak self] keyCode in
            self?.handleKeyDown(keyCode)
        }
    }

    public func stop() {
        keyboardMonitor.stop()
        soundPlayer.stopAll()
    }

    @discardableResult
    public func playTestSound() -> Bool {
        soundPlayer.play(index: 0)
    }

    public func setScheme(_ schemeName: String) throws {
        guard schemes.contains(where: { $0.name == schemeName }) else {
            throw TickeysControllerError.unknownScheme(schemeName)
        }

        currentPreference = UserPreference(
            scheme: schemeName,
            volume: currentPreference.volume,
            pitch: currentPreference.pitch,
            filterList: currentPreference.filterList,
            filterListMode: currentPreference.filterListMode
        )
        preferenceStore.save(currentPreference)
        try loadCurrentScheme()
    }

    public func setVolume(_ volume: Float) {
        currentPreference = UserPreference(
            scheme: currentPreference.scheme,
            volume: volume,
            pitch: currentPreference.pitch,
            filterList: currentPreference.filterList,
            filterListMode: currentPreference.filterListMode
        )
        soundPlayer.setVolume(volume)
        preferenceStore.save(currentPreference)
    }

    public func setPitch(_ pitch: Float) {
        currentPreference = UserPreference(
            scheme: currentPreference.scheme,
            volume: currentPreference.volume,
            pitch: pitch,
            filterList: currentPreference.filterList,
            filterListMode: currentPreference.filterListMode
        )
        soundPlayer.setPitch(pitch)
        preferenceStore.save(currentPreference)
    }

    public func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    public func applyActiveApp(name: String?) {
        activeAppName = name
        recomputeMuteForActiveApp()
    }

    public func setFilterList(_ filterList: [String]) {
        currentPreference = UserPreference(
            scheme: currentPreference.scheme,
            volume: currentPreference.volume,
            pitch: currentPreference.pitch,
            filterList: filterList,
            filterListMode: currentPreference.filterListMode
        )
        preferenceStore.save(currentPreference)
        recomputeMuteForActiveApp()
    }

    public func setFilterListMode(_ mode: FilterListMode) {
        currentPreference = UserPreference(
            scheme: currentPreference.scheme,
            volume: currentPreference.volume,
            pitch: currentPreference.pitch,
            filterList: currentPreference.filterList,
            filterListMode: mode
        )
        preferenceStore.save(currentPreference)
        recomputeMuteForActiveApp()
    }

    private func handleKeyDown(_ keyCode: UInt8) {
        NSLog("TickeysSwift: keyDown keyCode=%d muted=%@", Int(keyCode), String(isMuted))
        let shouldOpenSettings = sequenceDetector.record(keyCode: keyCode)
        if shouldOpenSettings {
            onSettingsRequested()
            return
        }

        guard !isMuted else {
            return
        }

        let now = UInt64(Date().timeIntervalSince1970 * 1_000)
        guard !throttler.shouldSuppress(keyCode: keyCode, atMilliseconds: now) else {
            return
        }

        guard let index = mapper.soundIndex(forKeyCode: keyCode) else {
            return
        }

        soundPlayer.play(index: index)
    }

    private func loadCurrentScheme() throws {
        guard let scheme = schemes.first(where: { $0.name == currentPreference.scheme }) else {
            throw TickeysControllerError.unknownScheme(currentPreference.scheme)
        }

        mapper = KeySoundMapper(scheme: scheme)
        let files = scheme.files.map { resourceBaseURL.appendingPathComponent(scheme.name).appendingPathComponent($0) }
        try soundPlayer.load(files: files)
    }

    private func recomputeMuteForActiveApp() {
        isMuted = AppFilterPolicy.shouldMute(
            appName: activeAppName,
            filterList: currentPreference.filterList,
            mode: currentPreference.filterListMode
        )
    }
}
