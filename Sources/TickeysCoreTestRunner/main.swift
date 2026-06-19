import Foundation
import TickeysCore

@main
struct TickeysCoreTestRunner {
    static func main() throws {
        try testDecodesBundledSchemesJsonWithoutChangingFormat()
        try testInvalidJsonReportsSchemeLoadingError()
        try testEmptySchemeListIsRejected()
        testDefaultPreferenceUsesFirstSchemeAndLegacyDefaults()
        testStoreFallsBackToFirstSchemeWhenSavedSchemeIsMissing()
        testImporterCopiesLegacyPreferencesWhenNewPreferencesDoNotExist()
        testImporterDoesNotOverwriteExistingNewPreferences()
        testKeySoundMapperUsesSpecificKeyAudioMap()
        testKeySoundMapperUsesModuloForOrdinaryKeys()
        testKeySoundMapperReturnsNilWhenNonUniqueCountIsZero()
        testKeySoundMapperReturnsNilWhenMappedIndexIsOutOfBounds()
        testRepeatedKeyThrottlerSuppressesSameKeyWithinWindow()
        testKeySequenceDetectorDetectsQAZ123Variants()
        try testAVAudioEngineSoundPlayerLoadsBundledWavFiles()
        try testAVAudioEngineSoundPlayerReportsMissingFile()
        try testAVAudioEngineSoundPlayerUpdatesVolumeAndPitch()
        try testAVAudioEngineSoundPlayerIgnoresOutOfBoundsPlayIndex()
        testAccessibilityPermissionCheckerCanBeInjected()
        testAccessibilityPermissionRecoveryRequestsSystemPrompt()
        testKeyboardMonitorRefusesToStartWithoutPermission()
        testKeyboardMonitorDefaultConfigurationMatchesLegacyEventTap()
        try testTickeysControllerStartsWithPreferenceAndMonitor()
        try testTickeysControllerPlaysMappedSoundOnKeyDown()
        try testTickeysControllerCanPlayDiagnosticSound()
        try testTickeysControllerOpensSettingsSequenceBeforePlayback()
        try testTickeysControllerMutesPlayback()
        try testTickeysControllerPersistsRuntimeChanges()
        try testSettingsViewModelLoadsControllerState()
        try testSettingsViewModelUpdatesSchemeVolumeAndPitch()
        try testSettingsViewModelPlaysTestSound()
        try testSettingsViewModelMapsPitchSliderToEnginePitch()
        try testSettingsViewModelAddsAndRemovesFilterApps()
        try testSettingsViewModelAddsFilterAppsFromAppURLs()
        testAppFilterPolicyBlacklistAndWhitelistModes()
        try testTickeysControllerRecomputesMuteWhenFilterChanges()
        testFrontmostAppObserverPublishesActivatedAppNames()
        testMenuBarCoordinatorDispatchesCommands()
        testNotificationCenterRecordsLifecycleNotifications()
        testLinkOpenerOpensExpectedURLs()
        testUpdateCheckerParsesNewerVersion()
        testUpdateCheckerParsesLegacyPayload()
        try testAppLifecycleCoordinatorRestartsControllerOnWake()
        testAppBundleConfigurationUsesSwiftRewriteIdentity()
        testAppBundleInfoPlistContainsRequiredKeys()
        print("TickeysCoreTestRunner: all tests passed")
    }
}

private func testDecodesBundledSchemesJsonWithoutChangingFormat() throws {
    let schemesURL = try resourceURL("Resources/data/schemes.json")

    let schemes = try SchemeLoader().loadSchemes(from: schemesURL)

    expectEqual(schemes.count, 7)
    expectEqual(schemes.map(\.name), [
        "bubble",
        "typewriter",
        "mechanical",
        "sword",
        "Cherry_G80_3000",
        "Cherry_G80_3494",
        "drum"
    ])
    expectEqual(schemes[0].displayName, "bubble")
    expectEqual(schemes[0].files, [
        "1.wav", "2.wav", "3.wav", "4.wav", "5.wav", "6.wav", "7.wav", "8.wav", "enter.wav"
    ])
    expectEqual(schemes[0].nonUniqueCount, 8)
    expectEqual(schemes[0].keyAudioMap[36], 8)
}

private func testInvalidJsonReportsSchemeLoadingError() throws {
    let directory = temporaryDirectory()
    let url = directory.appendingPathComponent("schemes.json")
    try Data("{ invalid json".utf8).write(to: url)

    expectThrows(SchemeLoadingError.invalidJSON) {
        _ = try SchemeLoader().loadSchemes(from: url)
    }
}

private func testEmptySchemeListIsRejected() throws {
    let directory = temporaryDirectory()
    let url = directory.appendingPathComponent("schemes.json")
    try Data("[]".utf8).write(to: url)

    expectThrows(SchemeLoadingError.emptySchemeList) {
        _ = try SchemeLoader().loadSchemes(from: url)
    }
}

private func testDefaultPreferenceUsesFirstSchemeAndLegacyDefaults() {
    let schemes = [
        AudioScheme(name: "bubble", displayName: "Bubble", files: ["1.wav"], nonUniqueCount: 1, keyAudioMap: [:]),
        AudioScheme(name: "drum", displayName: "Drum", files: ["1.wav"], nonUniqueCount: 1, keyAudioMap: [:])
    ]

    let preference = UserPreference.defaultPreference(availableSchemes: schemes)

    expectEqual(preference.scheme, "bubble")
    expectEqual(preference.volume, 0.5)
    expectEqual(preference.pitch, 1.0)
    expectEqual(preference.filterList, [])
    expectEqual(preference.filterListMode, .blacklist)
}

private func testStoreFallsBackToFirstSchemeWhenSavedSchemeIsMissing() {
    let suiteName = "TickeysCoreTests.new.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(true, forKey: PreferenceKeys.preferenceExists)
    defaults.set("missing", forKey: PreferenceKeys.audioScheme)
    defaults.set(Float(0.75), forKey: PreferenceKeys.volume)
    defaults.set(Float(1.25), forKey: PreferenceKeys.pitch)

    let schemes = [
        AudioScheme(name: "bubble", displayName: "Bubble", files: ["1.wav"], nonUniqueCount: 1, keyAudioMap: [:])
    ]

    let preference = PreferenceStore(defaults: defaults).load(availableSchemes: schemes)

    expectEqual(preference.scheme, "bubble")
    expectEqual(preference.volume, 0.75)
    expectEqual(preference.pitch, 1.25)
}

private func testImporterCopiesLegacyPreferencesWhenNewPreferencesDoNotExist() {
    let oldSuiteName = "TickeysCoreTests.old.\(UUID().uuidString)"
    let newSuiteName = "TickeysCoreTests.new.\(UUID().uuidString)"
    let oldDefaults = UserDefaults(suiteName: oldSuiteName)!
    let newDefaults = UserDefaults(suiteName: newSuiteName)!
    defer {
        oldDefaults.removePersistentDomain(forName: oldSuiteName)
        newDefaults.removePersistentDomain(forName: newSuiteName)
    }

    oldDefaults.set(true, forKey: PreferenceKeys.preferenceExists)
    oldDefaults.set("drum", forKey: PreferenceKeys.audioScheme)
    oldDefaults.set(Float(0.8), forKey: PreferenceKeys.volume)
    oldDefaults.set(Float(1.4), forKey: PreferenceKeys.pitch)
    oldDefaults.set(["Terminal.app", "Safari.app"], forKey: PreferenceKeys.filterList)
    oldDefaults.set(FilterListMode.whitelist.rawValue, forKey: PreferenceKeys.filterListMode)

    let didImport = LegacyPreferenceImporter(
        legacyDefaults: oldDefaults,
        destinationDefaults: newDefaults
    ).importIfNeeded()

    expect(didImport)
    expectEqual(newDefaults.string(forKey: PreferenceKeys.audioScheme), "drum")
    expectEqual(newDefaults.float(forKey: PreferenceKeys.volume), 0.8)
    expectEqual(newDefaults.float(forKey: PreferenceKeys.pitch), 1.4)
    expectEqual(newDefaults.stringArray(forKey: PreferenceKeys.filterList), ["Terminal.app", "Safari.app"])
    expectEqual(newDefaults.integer(forKey: PreferenceKeys.filterListMode), FilterListMode.whitelist.rawValue)
}

private func testImporterDoesNotOverwriteExistingNewPreferences() {
    let oldSuiteName = "TickeysCoreTests.old.\(UUID().uuidString)"
    let newSuiteName = "TickeysCoreTests.new.\(UUID().uuidString)"
    let oldDefaults = UserDefaults(suiteName: oldSuiteName)!
    let newDefaults = UserDefaults(suiteName: newSuiteName)!
    defer {
        oldDefaults.removePersistentDomain(forName: oldSuiteName)
        newDefaults.removePersistentDomain(forName: newSuiteName)
    }

    oldDefaults.set(true, forKey: PreferenceKeys.preferenceExists)
    oldDefaults.set("drum", forKey: PreferenceKeys.audioScheme)
    newDefaults.set(true, forKey: PreferenceKeys.preferenceExists)
    newDefaults.set("bubble", forKey: PreferenceKeys.audioScheme)

    let didImport = LegacyPreferenceImporter(
        legacyDefaults: oldDefaults,
        destinationDefaults: newDefaults
    ).importIfNeeded()

    expect(!didImport)
    expectEqual(newDefaults.string(forKey: PreferenceKeys.audioScheme), "bubble")
}

private func testKeySoundMapperUsesSpecificKeyAudioMap() {
    let scheme = AudioScheme(
        name: "typewriter",
        displayName: "Typewriter",
        files: ["1.wav", "space.wav", "backspace.wav", "enter.wav"],
        nonUniqueCount: 1,
        keyAudioMap: [36: 3, 49: 1, 51: 2]
    )
    let mapper = KeySoundMapper(scheme: scheme)

    expectEqual(mapper.soundIndex(forKeyCode: 36), 3)
    expectEqual(mapper.soundIndex(forKeyCode: 49), 1)
    expectEqual(mapper.soundIndex(forKeyCode: 51), 2)
}

private func testKeySoundMapperUsesModuloForOrdinaryKeys() {
    let scheme = AudioScheme(
        name: "bubble",
        displayName: "Bubble",
        files: ["1.wav", "2.wav", "3.wav", "4.wav"],
        nonUniqueCount: 4,
        keyAudioMap: [:]
    )
    let mapper = KeySoundMapper(scheme: scheme)

    expectEqual(mapper.soundIndex(forKeyCode: 0), 0)
    expectEqual(mapper.soundIndex(forKeyCode: 5), 1)
    expectEqual(mapper.soundIndex(forKeyCode: 51), 3)
}

private func testKeySoundMapperReturnsNilWhenNonUniqueCountIsZero() {
    let scheme = AudioScheme(
        name: "silent",
        displayName: "Silent",
        files: ["1.wav"],
        nonUniqueCount: 0,
        keyAudioMap: [:]
    )
    let mapper = KeySoundMapper(scheme: scheme)

    expectEqual(mapper.soundIndex(forKeyCode: 12), nil)
}

private func testKeySoundMapperReturnsNilWhenMappedIndexIsOutOfBounds() {
    let scheme = AudioScheme(
        name: "bad",
        displayName: "Bad",
        files: ["1.wav"],
        nonUniqueCount: 2,
        keyAudioMap: [36: 4]
    )
    let mapper = KeySoundMapper(scheme: scheme)

    expectEqual(mapper.soundIndex(forKeyCode: 36), nil)
    expectEqual(mapper.soundIndex(forKeyCode: 3), nil)
}

private func testRepeatedKeyThrottlerSuppressesSameKeyWithinWindow() {
    var throttler = RepeatedKeyThrottler(windowMilliseconds: 120)

    expect(!throttler.shouldSuppress(keyCode: 12, atMilliseconds: 1_000))
    expect(throttler.shouldSuppress(keyCode: 12, atMilliseconds: 1_050))
    expect(!throttler.shouldSuppress(keyCode: 13, atMilliseconds: 1_080))
    expect(!throttler.shouldSuppress(keyCode: 12, atMilliseconds: 1_200))
}

private func testKeySequenceDetectorDetectsQAZ123Variants() {
    var detector = KeySequenceDetector()

    for key in [12, 0, 6, 18, 19] {
        expect(!detector.record(keyCode: UInt8(key)))
    }
    expect(detector.record(keyCode: 20))

    detector.reset()
    for key in [12, 0, 6, 83, 84] {
        expect(!detector.record(keyCode: UInt8(key)))
    }
    expect(detector.record(keyCode: 85))

    detector.reset()
    for key in [99, 12, 0, 6, 18, 19] {
        expect(!detector.record(keyCode: UInt8(key)))
    }
    expect(detector.record(keyCode: 20))
}

private func testAVAudioEngineSoundPlayerLoadsBundledWavFiles() throws {
    let file = try resourceURL("Resources/data/bubble/1.wav")
    let player: SoundPlayer = AVAudioEngineSoundPlayer(voiceCount: 2)

    try player.load(files: [file])

    expectEqual(player.loadedSoundCount, 1)
    expectEqual(player.voiceCount, 2)
}

private func testAVAudioEngineSoundPlayerReportsMissingFile() throws {
    let missingFile = temporaryDirectory().appendingPathComponent("missing.wav")
    let player = AVAudioEngineSoundPlayer(voiceCount: 2)

    expectThrows(SoundPlayerError.fileNotFound) {
        try player.load(files: [missingFile])
    }
}

private func testAVAudioEngineSoundPlayerUpdatesVolumeAndPitch() throws {
    let player = AVAudioEngineSoundPlayer(voiceCount: 2)

    player.setVolume(0.25)
    player.setPitch(1.5)

    expectEqual(player.volume, 0.25)
    expectEqual(player.pitch, 1.5)
}

private func testAVAudioEngineSoundPlayerIgnoresOutOfBoundsPlayIndex() throws {
    let file = try resourceURL("Resources/data/bubble/1.wav")
    let player = AVAudioEngineSoundPlayer(voiceCount: 2)
    try player.load(files: [file])

    expectEqual(player.play(index: 9), false)
    player.stopAll()
}

private func testAccessibilityPermissionCheckerCanBeInjected() {
    let denied = AccessibilityPermissionChecker(checkTrust: { prompt in
        expect(!prompt)
        return false
    })
    let allowed = AccessibilityPermissionChecker(checkTrust: { prompt in
        expect(prompt)
        return true
    })

    expect(!denied.isTrusted(prompt: false))
    expect(allowed.isTrusted(prompt: true))
}

private func testAccessibilityPermissionRecoveryRequestsSystemPrompt() {
    let recorder = BoolRecorder()
    let recovery = AccessibilityPermissionRecovery(
        permissionChecker: AccessibilityPermissionChecker(checkTrust: { prompt in
            recorder.append(prompt)
            return prompt
        })
    )

    expect(recovery.requestPermission())
    expectEqual(recorder.values, [true])
}

private func testKeyboardMonitorRefusesToStartWithoutPermission() {
    let monitor = KeyboardMonitor(
        permissionChecker: AccessibilityPermissionChecker(checkTrust: { _ in false })
    )

    expectThrows(KeyboardMonitorError.accessibilityPermissionRequired) {
        try monitor.start { _ in }
    }
    expect(!monitor.isRunning)
}

private func testKeyboardMonitorDefaultConfigurationMatchesLegacyEventTap() {
    let configuration = KeyboardMonitorConfiguration.default

    expectEqual(configuration.location, .hid)
    expectEqual(configuration.placement, .headInsert)
    expectEqual(configuration.options, .listenOnly)
    expectEqual(configuration.events, [.keyDown])
}

private func testTickeysControllerStartsWithPreferenceAndMonitor() throws {
    let scheme = controllerScheme(name: "bubble")
    let defaults = isolatedDefaults()
    defaults.set(true, forKey: PreferenceKeys.preferenceExists)
    defaults.set("bubble", forKey: PreferenceKeys.audioScheme)
    defaults.set(Float(0.75), forKey: PreferenceKeys.volume)
    defaults.set(Float(1.25), forKey: PreferenceKeys.pitch)

    let player = FakeSoundPlayer()
    let monitor = FakeKeyboardMonitor()
    let controller = TickeysController(
        schemes: [scheme],
        resourceBaseURL: temporaryDirectory(),
        preferenceStore: PreferenceStore(defaults: defaults),
        soundPlayer: player,
        keyboardMonitor: monitor
    )

    try controller.start()

    expectEqual(controller.currentPreference.scheme, "bubble")
    expectEqual(player.volume, 0.75)
    expectEqual(player.pitch, 1.25)
    expect(monitor.isRunning)
}

private func testTickeysControllerPlaysMappedSoundOnKeyDown() throws {
    let scheme = controllerScheme(name: "bubble")
    let player = FakeSoundPlayer()
    let monitor = FakeKeyboardMonitor()
    let controller = TickeysController(
        schemes: [scheme],
        resourceBaseURL: temporaryDirectory(),
        preferenceStore: PreferenceStore(defaults: isolatedDefaults()),
        soundPlayer: player,
        keyboardMonitor: monitor
    )

    try controller.start()
    monitor.send(keyCode: 5)

    expectEqual(player.playedIndices, [1])
}

private func testTickeysControllerCanPlayDiagnosticSound() throws {
    let scheme = controllerScheme(name: "bubble")
    let player = FakeSoundPlayer()
    let monitor = FakeKeyboardMonitor()
    let controller = TickeysController(
        schemes: [scheme],
        resourceBaseURL: temporaryDirectory(),
        preferenceStore: PreferenceStore(defaults: isolatedDefaults()),
        soundPlayer: player,
        keyboardMonitor: monitor
    )

    try controller.start()
    controller.setMuted(true)

    expect(controller.isListening)
    expect(controller.playTestSound())
    expectEqual(player.playedIndices, [0])
}

private func testTickeysControllerOpensSettingsSequenceBeforePlayback() throws {
    let scheme = controllerScheme(name: "bubble")
    let player = FakeSoundPlayer()
    let monitor = FakeKeyboardMonitor()
    var didRequestSettings = false
    let controller = TickeysController(
        schemes: [scheme],
        resourceBaseURL: temporaryDirectory(),
        preferenceStore: PreferenceStore(defaults: isolatedDefaults()),
        soundPlayer: player,
        keyboardMonitor: monitor,
        onSettingsRequested: { didRequestSettings = true }
    )

    try controller.start()
    for key in [12, 0, 6, 18, 19, 20] {
        monitor.send(keyCode: UInt8(key))
    }

    expect(didRequestSettings)
    expect(player.playedIndices.count < 6)
}

private func testTickeysControllerMutesPlayback() throws {
    let scheme = controllerScheme(name: "bubble")
    let player = FakeSoundPlayer()
    let monitor = FakeKeyboardMonitor()
    let controller = TickeysController(
        schemes: [scheme],
        resourceBaseURL: temporaryDirectory(),
        preferenceStore: PreferenceStore(defaults: isolatedDefaults()),
        soundPlayer: player,
        keyboardMonitor: monitor
    )

    try controller.start()
    controller.setMuted(true)
    monitor.send(keyCode: 5)

    expectEqual(player.playedIndices, [])
}

private func testTickeysControllerPersistsRuntimeChanges() throws {
    let schemeA = controllerScheme(name: "bubble")
    let schemeB = controllerScheme(name: "drum")
    let defaults = isolatedDefaults()
    let controller = TickeysController(
        schemes: [schemeA, schemeB],
        resourceBaseURL: temporaryDirectory(),
        preferenceStore: PreferenceStore(defaults: defaults),
        soundPlayer: FakeSoundPlayer(),
        keyboardMonitor: FakeKeyboardMonitor()
    )

    try controller.start()
    try controller.setScheme("drum")
    controller.setVolume(0.2)
    controller.setPitch(1.4)

    expectEqual(defaults.string(forKey: PreferenceKeys.audioScheme), "drum")
    expectEqual(defaults.float(forKey: PreferenceKeys.volume), 0.2)
    expectEqual(defaults.float(forKey: PreferenceKeys.pitch), 1.4)
}

private func testSettingsViewModelLoadsControllerState() throws {
    let bundle = try makeStartedController()
    let viewModel = SettingsViewModel(controller: bundle.controller)

    expectEqual(viewModel.availableSchemes.map(\.name), ["bubble", "drum"])
    expectEqual(viewModel.selectedSchemeName, "bubble")
    expectEqual(viewModel.volume, 0.5)
    expectEqual(viewModel.pitchSliderValue, 1.0)
    expectEqual(viewModel.filterList, [String]())
    expectEqual(viewModel.filterListMode, .blacklist)
}

private func testSettingsViewModelUpdatesSchemeVolumeAndPitch() throws {
    let bundle = try makeStartedController()
    let controller = bundle.controller
    let player = bundle.player
    let viewModel = SettingsViewModel(controller: controller)

    try viewModel.selectScheme("drum")
    viewModel.setVolume(0.25)
    viewModel.setPitchSliderValue(1.25)

    expectEqual(controller.currentPreference.scheme, "drum")
    expectEqual(player.volume, 0.25)
    expectApproximatelyEqual(player.pitch, Float(1.25 * (2.0 / 1.5)))
}

private func testSettingsViewModelPlaysTestSound() throws {
    let bundle = try makeStartedController()
    let viewModel = SettingsViewModel(controller: bundle.controller)

    expect(viewModel.playTestSound())
    expectEqual(bundle.player.playedIndices, [0])
}

private func testSettingsViewModelMapsPitchSliderToEnginePitch() throws {
    let controller = try makeStartedController().controller
    let viewModel = SettingsViewModel(controller: controller)

    expectApproximatelyEqual(viewModel.enginePitch(fromSliderValue: 0.8), 0.8)
    expectApproximatelyEqual(viewModel.enginePitch(fromSliderValue: 1.0), 1.0)
    expectApproximatelyEqual(viewModel.enginePitch(fromSliderValue: 1.5), 2.0)
    expectApproximatelyEqual(viewModel.sliderPitch(fromEnginePitch: 2.0), 1.5)
}

private func testSettingsViewModelAddsAndRemovesFilterApps() throws {
    let bundle = try makeStartedController()
    let viewModel = SettingsViewModel(controller: bundle.controller)

    viewModel.addFilterApps(["Terminal.app", "Safari.app", "Terminal.app"])
    expectEqual(viewModel.filterList, ["Terminal.app", "Safari.app"])

    viewModel.removeFilterApp(atOffsets: [0])
    expectEqual(viewModel.filterList, ["Safari.app"])
    expectEqual(bundle.defaults.stringArray(forKey: PreferenceKeys.filterList), ["Safari.app"])
}

private func testSettingsViewModelAddsFilterAppsFromAppURLs() throws {
    let bundle = try makeStartedController()
    let viewModel = SettingsViewModel(controller: bundle.controller)

    viewModel.addFilterAppURLs([
        URL(fileURLWithPath: "/Applications/Safari.app"),
        URL(fileURLWithPath: "/Applications/Utilities/Terminal.app"),
        URL(fileURLWithPath: "/Applications/README.txt"),
        URL(fileURLWithPath: "/Applications/Safari.app")
    ])

    expectEqual(viewModel.filterList, ["Safari.app", "Terminal.app"])
    expectEqual(bundle.defaults.stringArray(forKey: PreferenceKeys.filterList), ["Safari.app", "Terminal.app"])
}

private func testAppFilterPolicyBlacklistAndWhitelistModes() {
    expect(AppFilterPolicy.shouldMute(appName: "Terminal.app", filterList: ["Terminal.app"], mode: .blacklist))
    expect(!AppFilterPolicy.shouldMute(appName: "Safari.app", filterList: ["Terminal.app"], mode: .blacklist))
    expect(!AppFilterPolicy.shouldMute(appName: "Terminal.app", filterList: ["Terminal.app"], mode: .whitelist))
    expect(AppFilterPolicy.shouldMute(appName: "Safari.app", filterList: ["Terminal.app"], mode: .whitelist))
}

private func testTickeysControllerRecomputesMuteWhenFilterChanges() throws {
    let bundle = try makeStartedController()
    let controller = bundle.controller

    controller.applyActiveApp(name: "Terminal.app")
    expect(!controller.isMuted)

    controller.setFilterList(["Terminal.app"])
    controller.setFilterListMode(.blacklist)
    expect(controller.isMuted)

    controller.setFilterListMode(.whitelist)
    expect(!controller.isMuted)

    controller.applyActiveApp(name: "Safari.app")
    expect(controller.isMuted)
}

private func testFrontmostAppObserverPublishesActivatedAppNames() {
    let observer = FrontmostAppObserver()
    var received: [String] = []
    observer.onActiveAppChanged = { received.append($0) }

    observer.handleActivatedApp(bundleURL: URL(fileURLWithPath: "/Applications/Terminal.app"))
    observer.handleActivatedApp(bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"))

    expectEqual(received, ["Terminal.app", "Safari.app"])
}

private func testMenuBarCoordinatorDispatchesCommands() {
    var requestedSettings = false
    var requestedQuit = false
    let coordinator = MenuBarCoordinator(
        onOpenSettings: { requestedSettings = true },
        onQuit: { requestedQuit = true }
    )

    coordinator.perform(.openSettings)
    coordinator.perform(.quit)

    expect(requestedSettings)
    expect(requestedQuit)
}

private func testNotificationCenterRecordsLifecycleNotifications() {
    let notificationCenter = RecordingNotificationService()

    notificationCenter.notify(.startupReady)
    notificationCenter.notify(.accessibilityPermissionMissing)
    notificationCenter.notify(.updateAvailable(version: "2.0.0", url: URL(string: "https://example.com")!))

    expectEqual(notificationCenter.notifications.count, 3)
    expectEqual(notificationCenter.notifications[0].kind, .startupReady)
    expectEqual(notificationCenter.notifications[1].kind, .accessibilityPermissionMissing)
    expectEqual(notificationCenter.notifications[2].kind, .updateAvailable(version: "2.0.0", url: URL(string: "https://example.com")!))
    expectEqual(notificationCenter.notifications[2].url, URL(string: "https://example.com")!)
}

private func testLinkOpenerOpensExpectedURLs() {
    let recorder = URLRecorder()
    let opener = LinkOpener { url in
        recorder.append(url)
        return true
    }

    expect(opener.open(.homepage))

    expectEqual(recorder.urls, [URL(string: "https://github.com/zjjfly/Tickeys-Swift")!])
}

private func testUpdateCheckerParsesNewerVersion() {
    let checker = UpdateChecker(
        currentVersion: "1.0.0",
        fetch: { _ in Data(#"{"version":"1.2.0","url":"https://example.com/Tickeys-Swift.zip"}"#.utf8) }
    )

    let result = checker.check(updateURL: URL(string: "https://example.com/update.json")!)

    expectEqual(result, .available(UpdateInfo(
        version: "1.2.0",
        url: URL(string: "https://example.com/Tickeys-Swift.zip")!
    )))
}

private func testUpdateCheckerParsesLegacyPayload() {
    let checker = UpdateChecker(
        currentVersion: "0.5.0",
        fetch: { _ in Data(#"{"Version":"0.6.0","WhatsNew":"Swift rewrite"}"#.utf8) }
    )

    let updateURL = URL(string: "https://example.com/check-update")!
    let result = checker.check(updateURL: updateURL)

    expectEqual(result, .available(UpdateInfo(version: "0.6.0", url: updateURL)))
}

private func testAppLifecycleCoordinatorRestartsControllerOnWake() throws {
    let bundle = try makeStartedController()
    let notifications = RecordingNotificationService()
    let wakeObserver = ManualWakeObserver()
    let coordinator = AppLifecycleCoordinator(
        controller: bundle.controller,
        notificationService: notifications,
        wakeObserver: wakeObserver
    )

    coordinator.start()
    wakeObserver.sendWake()

    expectEqual(bundle.monitor.startCount, 2)
    expectEqual(notifications.notifications.map(\.kind), [.startupReady])
}

private func testAppBundleConfigurationUsesSwiftRewriteIdentity() {
    let configuration = AppBundleConfiguration.default

    expectEqual(configuration.productName, "Tickeys-Swift")
    expectEqual(configuration.bundleIdentifier, "github.zjjfly.Tickeys-Swift")
    expectEqual(configuration.executableName, "Tickeys-Swift")
    expectEqual(configuration.iconFileName, "tickeys-swift")
    expectEqual(configuration.isAgentApp, true)
}

private func testAppBundleInfoPlistContainsRequiredKeys() {
    let plist = AppBundleInfoPlist(configuration: .default).dictionary

    expectEqual(plist["CFBundleIdentifier"] as? String, "github.zjjfly.Tickeys-Swift")
    expectEqual(plist["CFBundleExecutable"] as? String, "Tickeys-Swift")
    expectEqual(plist["CFBundleIconFile"] as? String, "tickeys-swift")
    expectEqual(plist["CFBundleLocalizations"] as? [String], ["Base", "zh-Hans"])
    expectEqual(plist["CFBundlePackageType"] as? String, "APPL")
    expectEqual(plist["LSUIElement"] as? Bool, true)
    expectEqual(plist["LSMultipleInstancesProhibited"] as? Bool, true)
    expectEqual(plist["NSHighResolutionCapable"] as? Bool, true)
}

private func resourceURL(_ relativePath: String) throws -> URL {
    var url = URL(fileURLWithPath: #filePath)
    while url.pathComponents.count > 1 {
        url.deleteLastPathComponent()
        let candidate = url.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
    }
    throw TestFailure("Missing resource \(relativePath)")
}

private func temporaryDirectory() -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("TickeysCoreTestRunner")
        .appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String = "Expectation failed") {
    if !condition() {
        fatalError(message)
    }
}

private func expectEqual<T: Equatable>(_ actual: T, _ expected: T) {
    if actual != expected {
        fatalError("Expected \(expected), got \(actual)")
    }
}

private func expectApproximatelyEqual(_ actual: Float, _ expected: Float, tolerance: Float = 0.0001) {
    if abs(actual - expected) > tolerance {
        fatalError("Expected \(expected), got \(actual)")
    }
}

private func expectThrows<E: Error & Equatable>(_ expected: E, operation: () throws -> Void) {
    do {
        try operation()
        fatalError("Expected error \(expected), got success")
    } catch let error as E {
        if error != expected {
            fatalError("Expected error \(expected), got \(error)")
        }
    } catch {
        fatalError("Expected error \(expected), got \(error)")
    }
}

private struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

private func controllerScheme(name: String) -> AudioScheme {
    AudioScheme(
        name: name,
        displayName: name,
        files: ["1.wav", "2.wav", "3.wav", "4.wav"],
        nonUniqueCount: 4,
        keyAudioMap: [36: 3]
    )
}

private func makeStartedController() throws -> ControllerBundle {
    let defaults = isolatedDefaults()
    let player = FakeSoundPlayer()
    let monitor = FakeKeyboardMonitor()
    let controller = TickeysController(
        schemes: [controllerScheme(name: "bubble"), controllerScheme(name: "drum")],
        resourceBaseURL: temporaryDirectory(),
        preferenceStore: PreferenceStore(defaults: defaults),
        soundPlayer: player,
        keyboardMonitor: monitor
    )
    try controller.start()
    return ControllerBundle(controller: controller, player: player, monitor: monitor, defaults: defaults)
}

private struct ControllerBundle {
    let controller: TickeysController
    let player: FakeSoundPlayer
    let monitor: FakeKeyboardMonitor
    let defaults: UserDefaults
}

private func isolatedDefaults() -> UserDefaults {
    let suiteName = "TickeysCoreTests.controller.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

private final class FakeSoundPlayer: SoundPlayer {
    var loadedSoundCount = 0
    var voiceCount = 2
    var volume: Float = 1
    var pitch: Float = 1
    var loadedFiles: [URL] = []
    var playedIndices: [Int] = []
    var didStopAll = false

    func load(files: [URL]) throws {
        loadedFiles = files
        loadedSoundCount = files.count
    }

    func setVolume(_ volume: Float) {
        self.volume = volume
    }

    func setPitch(_ pitch: Float) {
        self.pitch = pitch
    }

    func play(index: Int) -> Bool {
        playedIndices.append(index)
        return true
    }

    func stopAll() {
        didStopAll = true
    }
}

private final class FakeKeyboardMonitor: KeyboardMonitoring {
    var isRunning = false
    var startCount = 0
    private var handler: ((UInt8) -> Void)?

    func start(onKeyDown: @escaping (UInt8) -> Void) throws {
        handler = onKeyDown
        isRunning = true
        startCount += 1
    }

    func stop() {
        handler = nil
        isRunning = false
    }

    func send(keyCode: UInt8) {
        handler?(keyCode)
    }
}

private final class URLRecorder: @unchecked Sendable {
    private(set) var urls: [URL] = []

    func append(_ url: URL) {
        urls.append(url)
    }
}

private final class BoolRecorder: @unchecked Sendable {
    private(set) var values: [Bool] = []

    func append(_ value: Bool) {
        values.append(value)
    }
}
