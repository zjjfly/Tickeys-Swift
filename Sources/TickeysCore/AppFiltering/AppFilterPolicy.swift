public enum AppFilterPolicy {
    public static func shouldMute(appName: String?, filterList: [String], mode: FilterListMode) -> Bool {
        guard let appName, !appName.isEmpty else {
            return false
        }

        let isInList = filterList.contains(appName)
        switch mode {
        case .blacklist:
            return isInList
        case .whitelist:
            return !isInList
        }
    }
}
