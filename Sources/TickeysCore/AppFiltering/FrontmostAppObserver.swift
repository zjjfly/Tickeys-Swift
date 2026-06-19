#if canImport(AppKit)
import AppKit
import Foundation

public final class FrontmostAppObserver: @unchecked Sendable {
    public var onActiveAppChanged: ((String) -> Void)?

    private let workspace: NSWorkspace
    private var observer: NSObjectProtocol?

    public init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    deinit {
        stop()
    }

    public func start() {
        stop()
        observer = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            else {
                return
            }
            self?.handleActivatedApp(bundleURL: app.bundleURL)
        }

        handleActivatedApp(bundleURL: workspace.frontmostApplication?.bundleURL)
    }

    public func stop() {
        if let observer {
            workspace.notificationCenter.removeObserver(observer)
        }
        observer = nil
    }

    public func handleActivatedApp(bundleURL: URL?) {
        guard let appName = bundleURL?.lastPathComponent, !appName.isEmpty else {
            return
        }
        onActiveAppChanged?(appName)
    }
}
#endif
