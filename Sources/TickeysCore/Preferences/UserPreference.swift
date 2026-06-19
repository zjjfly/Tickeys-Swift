public enum FilterListMode: Int, Equatable {
    case blacklist = 0
    case whitelist = 1

    public static func fromStoredValue(_ value: Int) -> FilterListMode {
        FilterListMode(rawValue: value) ?? .blacklist
    }
}

public struct UserPreference: Equatable {
    public let scheme: String
    public let volume: Float
    public let pitch: Float
    public let filterList: [String]
    public let filterListMode: FilterListMode

    public init(
        scheme: String,
        volume: Float,
        pitch: Float,
        filterList: [String] = [],
        filterListMode: FilterListMode = .blacklist
    ) {
        self.scheme = scheme
        self.volume = volume
        self.pitch = pitch
        self.filterList = filterList
        self.filterListMode = filterListMode
    }

    public static func defaultPreference(availableSchemes schemes: [AudioScheme]) -> UserPreference {
        UserPreference(
            scheme: schemes.first?.name ?? "",
            volume: 0.5,
            pitch: 1.0,
            filterList: [],
            filterListMode: .blacklist
        )
    }
}
