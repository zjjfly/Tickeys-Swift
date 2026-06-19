import Foundation

public enum AppNotificationKind: Equatable, Sendable {
    case startupReady
    case accessibilityPermissionMissing
    case updateAvailable(version: String, url: URL)
}

public struct AppNotification: Equatable, Sendable {
    public let kind: AppNotificationKind
    public let title: String
    public let message: String
    public let url: URL?

    public init(kind: AppNotificationKind) {
        self.kind = kind

        switch kind {
        case .startupReady:
            self.title = LocalizedStrings.text("Tickeys_Running")
            self.message = LocalizedStrings.text("press_qaz123")
            self.url = nil
        case .accessibilityPermissionMissing:
            self.title = LocalizedStrings.text("accessibility_permission_required")
            self.message = LocalizedStrings.text("accessibility_permission_notification")
            self.url = nil
        case let .updateAvailable(version, url):
            self.title = LocalizedStrings.format("update_available_format", version)
            self.message = LocalizedStrings.text("open_download_page_to_update")
            self.url = url
        }
    }
}

public protocol NotificationService: AnyObject {
    func notify(_ kind: AppNotificationKind)
}

public final class RecordingNotificationService: NotificationService {
    public private(set) var notifications: [AppNotification] = []

    public init() {}

    public func notify(_ kind: AppNotificationKind) {
        notifications.append(AppNotification(kind: kind))
    }
}

#if canImport(UserNotifications)
import UserNotifications

public final class UserNotificationService: NotificationService {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func notify(_ kind: AppNotificationKind) {
        let notification = AppNotification(kind: kind)
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        if let url = notification.url {
            content.userInfo = ["url": url.absoluteString]
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}
#endif
