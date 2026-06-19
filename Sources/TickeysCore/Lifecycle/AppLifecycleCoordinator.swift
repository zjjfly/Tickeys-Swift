import Foundation

public protocol WakeObserving: AnyObject {
    var onWake: (() -> Void)? { get set }
    func start()
    func stop()
}

public final class ManualWakeObserver: WakeObserving {
    public var onWake: (() -> Void)?
    public private(set) var isRunning = false

    public init() {}

    public func start() {
        isRunning = true
    }

    public func stop() {
        isRunning = false
    }

    public func sendWake() {
        onWake?()
    }
}

public final class AppLifecycleCoordinator {
    private let controller: TickeysController
    private let notificationService: NotificationService
    private let wakeObserver: WakeObserving

    public init(
        controller: TickeysController,
        notificationService: NotificationService,
        wakeObserver: WakeObserving
    ) {
        self.controller = controller
        self.notificationService = notificationService
        self.wakeObserver = wakeObserver
    }

    public func start() {
        wakeObserver.onWake = { [weak self] in
            self?.restartController()
        }
        wakeObserver.start()
        notificationService.notify(.startupReady)
    }

    public func stop() {
        wakeObserver.stop()
        controller.stop()
    }

    private func restartController() {
        controller.stop()
        do {
            try controller.start()
        } catch TickeysControllerError.emptySchemeList {
            notificationService.notify(.accessibilityPermissionMissing)
        } catch KeyboardMonitorError.accessibilityPermissionRequired {
            notificationService.notify(.accessibilityPermissionMissing)
        } catch {
            notificationService.notify(.accessibilityPermissionMissing)
        }
    }
}

#if canImport(AppKit)
import AppKit

public final class WorkspaceWakeObserver: WakeObserving, @unchecked Sendable {
    public var onWake: (() -> Void)?

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
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onWake?()
        }
    }

    public func stop() {
        if let observer {
            workspace.notificationCenter.removeObserver(observer)
        }
        observer = nil
    }
}
#endif
