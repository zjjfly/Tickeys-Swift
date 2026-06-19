import ApplicationServices
import Foundation

public struct AccessibilityPermissionChecker: Sendable {
    private let checkTrust: @Sendable (Bool) -> Bool

    public init(checkTrust: @escaping @Sendable (Bool) -> Bool = AccessibilityPermissionChecker.systemTrustCheck(prompt:)) {
        self.checkTrust = checkTrust
    }

    public func isTrusted(prompt: Bool) -> Bool {
        checkTrust(prompt)
    }

    public static func systemTrustCheck(prompt: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}

public struct AccessibilityPermissionRecovery: Sendable {
    private let permissionChecker: AccessibilityPermissionChecker

    public init(permissionChecker: AccessibilityPermissionChecker = AccessibilityPermissionChecker()) {
        self.permissionChecker = permissionChecker
    }

    public func requestPermission() -> Bool {
        permissionChecker.isTrusted(prompt: true)
    }
}
