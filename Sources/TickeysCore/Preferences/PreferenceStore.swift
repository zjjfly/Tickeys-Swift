import Foundation

public struct PreferenceStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load(availableSchemes schemes: [AudioScheme]) -> UserPreference {
        let fallback = UserPreference.defaultPreference(availableSchemes: schemes)

        guard defaults.object(forKey: PreferenceKeys.preferenceExists) != nil else {
            save(fallback)
            return fallback
        }

        let storedScheme = defaults.string(forKey: PreferenceKeys.audioScheme) ?? fallback.scheme
        let validScheme = schemes.contains { $0.name == storedScheme } ? storedScheme : fallback.scheme

        let volume = defaults.object(forKey: PreferenceKeys.volume) == nil
            ? fallback.volume
            : defaults.float(forKey: PreferenceKeys.volume)
        let pitch = defaults.object(forKey: PreferenceKeys.pitch) == nil
            ? fallback.pitch
            : defaults.float(forKey: PreferenceKeys.pitch)
        let filterList = defaults.stringArray(forKey: PreferenceKeys.filterList) ?? []
        let filterListMode = FilterListMode.fromStoredValue(defaults.integer(forKey: PreferenceKeys.filterListMode))

        return UserPreference(
            scheme: validScheme,
            volume: volume,
            pitch: pitch,
            filterList: filterList,
            filterListMode: filterListMode
        )
    }

    public func save(_ preference: UserPreference) {
        defaults.set(true, forKey: PreferenceKeys.preferenceExists)
        defaults.set(preference.scheme, forKey: PreferenceKeys.audioScheme)
        defaults.set(preference.volume, forKey: PreferenceKeys.volume)
        defaults.set(preference.pitch, forKey: PreferenceKeys.pitch)
        defaults.set(preference.filterList, forKey: PreferenceKeys.filterList)
        defaults.set(preference.filterListMode.rawValue, forKey: PreferenceKeys.filterListMode)
    }
}
