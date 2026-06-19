import Foundation

public enum LocalizedStrings {
    public static func text(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, comment: "")
    }

    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }
}
