import Foundation

public enum MenuBarCommand: Equatable, Sendable {
    case openSettings
    case quit
}

public final class MenuBarCoordinator {
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void

    public init(
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
    }

    public func perform(_ command: MenuBarCommand) {
        switch command {
        case .openSettings:
            onOpenSettings()
        case .quit:
            onQuit()
        }
    }
}
