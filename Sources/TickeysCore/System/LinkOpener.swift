import Foundation

public enum TickeysLink: Equatable, Sendable {
    case homepage
    case custom(URL)

    public var url: URL {
        switch self {
        case .homepage:
            return URL(string: "https://github.com/zjjfly/Tickeys-Swift")!
        case let .custom(url):
            return url
        }
    }
}

public struct LinkOpener: Sendable {
    private let openURL: @Sendable (URL) -> Bool

    public init(openURL: @escaping @Sendable (URL) -> Bool) {
        self.openURL = openURL
    }

    public func open(_ link: TickeysLink) -> Bool {
        openURL(link.url)
    }
}

#if canImport(AppKit)
import AppKit

public extension LinkOpener {
    @MainActor
    static let system = LinkOpener { url in
        NSWorkspace.shared.open(url)
    }
}
#endif
