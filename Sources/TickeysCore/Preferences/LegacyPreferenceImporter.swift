import Foundation

public struct LegacyPreferenceImporter {
    private let legacyDefaults: UserDefaults
    private let destinationDefaults: UserDefaults

    public init(
        legacyDefaults: UserDefaults = UserDefaults(suiteName: "com.yingDev.Tickeys") ?? .standard,
        destinationDefaults: UserDefaults = .standard
    ) {
        self.legacyDefaults = legacyDefaults
        self.destinationDefaults = destinationDefaults
    }

    @discardableResult
    public func importIfNeeded() -> Bool {
        guard destinationDefaults.object(forKey: PreferenceKeys.preferenceExists) == nil else {
            return false
        }
        guard legacyDefaults.object(forKey: PreferenceKeys.preferenceExists) != nil else {
            return false
        }

        copyObject(forKey: PreferenceKeys.audioScheme)
        copyObject(forKey: PreferenceKeys.volume)
        copyObject(forKey: PreferenceKeys.pitch)
        copyObject(forKey: PreferenceKeys.filterList)
        copyObject(forKey: PreferenceKeys.filterListMode)
        destinationDefaults.set(true, forKey: PreferenceKeys.preferenceExists)
        return true
    }

    private func copyObject(forKey key: String) {
        guard let value = legacyDefaults.object(forKey: key) else {
            return
        }
        destinationDefaults.set(value, forKey: key)
    }
}
