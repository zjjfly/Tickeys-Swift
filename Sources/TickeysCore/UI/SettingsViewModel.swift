import Foundation

public final class SettingsViewModel {
    public private(set) var availableSchemes: [AudioScheme]
    public private(set) var selectedSchemeName: String
    public private(set) var volume: Float
    public private(set) var pitchSliderValue: Float
    public private(set) var filterList: [String]
    public private(set) var filterListMode: FilterListMode

    private let controller: TickeysController

    public init(controller: TickeysController) {
        self.controller = controller
        self.availableSchemes = controller.availableSchemes
        self.selectedSchemeName = controller.currentPreference.scheme
        self.volume = controller.currentPreference.volume
        self.pitchSliderValue = Self.sliderPitch(fromEnginePitch: controller.currentPreference.pitch)
        self.filterList = controller.currentPreference.filterList
        self.filterListMode = controller.currentPreference.filterListMode
    }

    public func selectScheme(_ schemeName: String) throws {
        try controller.setScheme(schemeName)
        selectedSchemeName = controller.currentPreference.scheme
    }

    public func setVolume(_ volume: Float) {
        self.volume = volume
        controller.setVolume(volume)
    }

    public func setPitchSliderValue(_ sliderValue: Float) {
        pitchSliderValue = sliderValue
        controller.setPitch(enginePitch(fromSliderValue: sliderValue))
    }

    public func playTestSound() -> Bool {
        controller.playTestSound()
    }

    public func setFilterListMode(_ mode: FilterListMode) {
        filterListMode = mode
        controller.setFilterListMode(mode)
    }

    public func addFilterApps(_ appNames: [String]) {
        var next = filterList
        for appName in appNames where !next.contains(appName) {
            next.append(appName)
        }
        filterList = next
        controller.setFilterList(next)
    }

    public func addFilterAppURLs(_ urls: [URL]) {
        addFilterApps(urls.compactMap(Self.appName(from:)))
    }

    public func removeFilterApp(atOffsets offsets: [Int]) {
        let removeSet = Set(offsets)
        filterList = filterList.enumerated()
            .filter { !removeSet.contains($0.offset) }
            .map(\.element)
        controller.setFilterList(filterList)
    }

    public func enginePitch(fromSliderValue sliderValue: Float) -> Float {
        Self.enginePitch(fromSliderValue: sliderValue)
    }

    public func sliderPitch(fromEnginePitch enginePitch: Float) -> Float {
        Self.sliderPitch(fromEnginePitch: enginePitch)
    }

    public static func enginePitch(fromSliderValue sliderValue: Float) -> Float {
        sliderValue > 1 ? sliderValue * (2.0 / 1.5) : sliderValue
    }

    public static func sliderPitch(fromEnginePitch enginePitch: Float) -> Float {
        enginePitch > 1 ? enginePitch * (1.5 / 2.0) : enginePitch
    }

    private static func appName(from url: URL) -> String? {
        guard url.pathExtension == "app" else {
            return nil
        }

        return url.lastPathComponent
    }
}
