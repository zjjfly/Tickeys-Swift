#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SwiftUI
import TickeysCore

@main
struct TickeysApp {
    static func main() {
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        NSApplication.shared.setActivationPolicy(.accessory)
        NSApplication.shared.run()
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: TickeysController?
    private var lifecycleCoordinator: AppLifecycleCoordinator?
    private var frontmostAppObserver: FrontmostAppObserver?
    private var settingsWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var lastStartupError: Error?
    private var didScheduleStartupRetry = false
    private var accessibilityRetryTimer: Timer?
    private var accessibilityRetryDeadline: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("TickeysSwift: applicationDidFinishLaunching")
        configureStatusItem()

        do {
            try startRuntime()
            scheduleStartupRetryIfNeeded()
        } catch {
            handleStartupFailure(error)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopAccessibilityRetryTimer()
        lifecycleCoordinator?.stop()
        frontmostAppObserver?.stop()
    }

    private func startRuntime() throws {
        guard let dataURL = Bundle.main.resourceURL?.appendingPathComponent("data") else {
            throw TickeysAppError.missingResourceDirectory
        }

        let schemes = try SchemeLoader().loadSchemes(from: dataURL.appendingPathComponent("schemes.json"))
        let controller = TickeysController(
            schemes: schemes,
            resourceBaseURL: dataURL,
            preferenceStore: PreferenceStore(),
            soundPlayer: AVAudioEngineSoundPlayer(voiceCount: 2),
            keyboardMonitor: KeyboardMonitor(),
            onSettingsRequested: { [weak self] in
                self?.showSettings()
            }
        )
        try controller.start()
        NSLog("TickeysSwift: runtime started, scheme=%@, listening=%@", controller.currentPreference.scheme, String(controller.isListening))

        let observer = FrontmostAppObserver()
        observer.onActiveAppChanged = { [weak controller] appName in
            controller?.applyActiveApp(name: appName)
        }
        observer.start()

        let lifecycle = AppLifecycleCoordinator(
            controller: controller,
            notificationService: UserNotificationService(),
            wakeObserver: WorkspaceWakeObserver()
        )
        lifecycle.start()

        self.controller = controller
        self.frontmostAppObserver = observer
        self.lifecycleCoordinator = lifecycle
    }

    private func restartRuntime() throws {
        lifecycleCoordinator?.stop()
        frontmostAppObserver?.stop()
        lifecycleCoordinator = nil
        frontmostAppObserver = nil
        controller = nil
        try startRuntime()
    }

    private func scheduleStartupRetryIfNeeded() {
        guard !didScheduleStartupRetry else {
            return
        }
        didScheduleStartupRetry = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.retryListeningAfterStartup()
        }
    }

    private func retryListeningAfterStartup() {
        NSLog("TickeysSwift: startup retryListening requested")
        do {
            try restartRuntime()
            lastStartupError = nil
            stopAccessibilityRetryTimer()
        } catch {
            handleStartupFailure(error)
        }
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "T"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: LocalizedStrings.text("menu_settings"), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: LocalizedStrings.text("menu_retry_listening"), action: #selector(retryListening), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: LocalizedStrings.text("menu_website"), action: #selector(openWebsite), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: LocalizedStrings.text("quit"), action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items {
            item.target = self
        }
        statusItem.menu = menu
        self.statusItem = statusItem
    }

    @objc private func openSettings() {
        showSettings()
    }

    @objc private func openWebsite() {
        _ = LinkOpener.system.open(.homepage)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func retryListening() {
        NSLog("TickeysSwift: retryListening requested")
        do {
            try restartRuntime()
            lastStartupError = nil
            stopAccessibilityRetryTimer()
        } catch {
            handleStartupFailure(error)
        }
    }

    private func showSettings() {
        guard let controller else {
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        if settingsWindow == nil {
            let view = SettingsView(viewModel: SettingsViewModel(controller: controller))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 460, height: 440),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Tickeys-Swift"
            window.contentView = NSHostingView(rootView: view)
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func handleStartupFailure(_ error: Error) {
        NSLog("TickeysSwift: startup failed: %@", String(describing: error))
        lastStartupError = error
        UserNotificationService().notify(.accessibilityPermissionMissing)

        if case KeyboardMonitorError.accessibilityPermissionRequired = error {
            _ = AccessibilityPermissionRecovery().requestPermission()
            startAccessibilityRetryTimer()
            showAccessibilityAlert()
        } else {
            stopAccessibilityRetryTimer()
            showStartupErrorAlert(error)
        }
    }

    private func startAccessibilityRetryTimer() {
        guard accessibilityRetryTimer == nil else {
            return
        }

        accessibilityRetryDeadline = Date().addingTimeInterval(120)
        accessibilityRetryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.retryListeningIfAccessibilityPermissionWasGranted()
            }
        }
    }

    private func stopAccessibilityRetryTimer() {
        accessibilityRetryTimer?.invalidate()
        accessibilityRetryTimer = nil
        accessibilityRetryDeadline = nil
    }

    private func retryListeningIfAccessibilityPermissionWasGranted() {
        if let deadline = accessibilityRetryDeadline, Date() >= deadline {
            NSLog("TickeysSwift: accessibility retry timed out")
            stopAccessibilityRetryTimer()
            return
        }

        guard AccessibilityPermissionChecker().isTrusted(prompt: false) else {
            return
        }

        NSLog("TickeysSwift: accessibility permission granted, retrying listening")
        do {
            try restartRuntime()
            lastStartupError = nil
            stopAccessibilityRetryTimer()
        } catch {
            handleStartupFailure(error)
        }
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = LocalizedStrings.text("accessibility_permission_required")
        alert.informativeText = LocalizedStrings.text("accessibility_permission_alert")
        alert.addButton(withTitle: LocalizedStrings.text("ok"))
        alert.runModal()
    }

    private func showStartupErrorAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = LocalizedStrings.text("startup_error_title")
        alert.informativeText = String(describing: error)
        alert.addButton(withTitle: LocalizedStrings.text("ok"))
        alert.runModal()
    }
}

private enum TickeysAppError: Error {
    case missingResourceDirectory
    case runtimeNotStarted
}
#else
@main
struct TickeysApp {
    static func main() {
        fatalError("TickeysApp requires AppKit and SwiftUI")
    }
}
#endif
