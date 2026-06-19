import ApplicationServices
import Foundation

public protocol KeyboardMonitoring: AnyObject {
    var isRunning: Bool { get }
    func start(onKeyDown: @escaping (UInt8) -> Void) throws
    func stop()
}

public enum KeyboardMonitorError: Error, Equatable, Sendable {
    case accessibilityPermissionRequired
    case eventTapCreationFailed
    case runLoopSourceCreationFailed
}

public enum KeyboardEventType: Equatable, Sendable {
    case keyDown
}

public enum KeyboardEventTapLocation: Equatable, Sendable {
    case hid

    var cgValue: CGEventTapLocation {
        switch self {
        case .hid:
            return .cghidEventTap
        }
    }
}

public enum KeyboardEventTapPlacement: Equatable, Sendable {
    case headInsert

    var cgValue: CGEventTapPlacement {
        switch self {
        case .headInsert:
            return .headInsertEventTap
        }
    }
}

public enum KeyboardEventTapOptions: Equatable, Sendable {
    case listenOnly

    var cgValue: CGEventTapOptions {
        switch self {
        case .listenOnly:
            return .listenOnly
        }
    }
}

public struct KeyboardMonitorConfiguration: Equatable, Sendable {
    public static let `default` = KeyboardMonitorConfiguration(
        location: .hid,
        placement: .headInsert,
        options: .listenOnly,
        events: [.keyDown]
    )

    public let location: KeyboardEventTapLocation
    public let placement: KeyboardEventTapPlacement
    public let options: KeyboardEventTapOptions
    public let events: [KeyboardEventType]

    public init(
        location: KeyboardEventTapLocation,
        placement: KeyboardEventTapPlacement,
        options: KeyboardEventTapOptions,
        events: [KeyboardEventType]
    ) {
        self.location = location
        self.placement = placement
        self.options = options
        self.events = events
    }

    var eventMask: CGEventMask {
        events.reduce(CGEventMask(0)) { mask, event in
            mask | event.mask
        }
    }
}

private extension KeyboardEventType {
    var mask: CGEventMask {
        switch self {
        case .keyDown:
            return CGEventMask(1 << CGEventType.keyDown.rawValue)
        }
    }
}

public final class KeyboardMonitor: KeyboardMonitoring {
    public typealias KeyHandler = (UInt8) -> Void

    public private(set) var isRunning = false

    private let configuration: KeyboardMonitorConfiguration
    private let permissionChecker: AccessibilityPermissionChecker
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var context: KeyboardMonitorContext?

    public init(
        configuration: KeyboardMonitorConfiguration = .default,
        permissionChecker: AccessibilityPermissionChecker = AccessibilityPermissionChecker()
    ) {
        self.configuration = configuration
        self.permissionChecker = permissionChecker
    }

    deinit {
        stop()
    }

    public func start(onKeyDown: @escaping KeyHandler) throws {
        guard permissionChecker.isTrusted(prompt: false) else {
            throw KeyboardMonitorError.accessibilityPermissionRequired
        }

        stop()

        let context = KeyboardMonitorContext(handler: onKeyDown)
        let contextPointer = Unmanaged.passUnretained(context).toOpaque()

        guard let eventTap = CGEvent.tapCreate(
            tap: configuration.location.cgValue,
            place: configuration.placement.cgValue,
            options: configuration.options.cgValue,
            eventsOfInterest: configuration.eventMask,
            callback: keyboardEventCallback,
            userInfo: contextPointer
        ) else {
            throw KeyboardMonitorError.eventTapCreationFailed
        }

        guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            CFMachPortInvalidate(eventTap)
            throw KeyboardMonitorError.runLoopSourceCreationFailed
        }

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.context = context
        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        isRunning = true
    }

    public func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        if context != nil {
            context = nil
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
    }
}

private final class KeyboardMonitorContext {
    let handler: KeyboardMonitor.KeyHandler

    init(handler: @escaping KeyboardMonitor.KeyHandler) {
        self.handler = handler
    }
}

private let keyboardEventCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard type == .keyDown, let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let context = Unmanaged<KeyboardMonitorContext>.fromOpaque(userInfo).takeUnretainedValue()
    let keyCode = UInt8(event.getIntegerValueField(.keyboardEventKeycode))
    context.handler(keyCode)
    return Unmanaged.passUnretained(event)
}
