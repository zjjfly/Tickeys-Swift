import Foundation

public struct UpdateInfo: Equatable, Sendable {
    public let version: String
    public let url: URL

    public init(version: String, url: URL) {
        self.version = version
        self.url = url
    }
}

public enum UpdateCheckResult: Equatable, Sendable {
    case current
    case available(UpdateInfo)
    case unavailable
}

public struct UpdateChecker {
    private struct Payload: Decodable {
        let version: String?
        let url: URL?
        let legacyVersion: String?
        let whatsNew: String?

        enum CodingKeys: String, CodingKey {
            case version
            case url
            case legacyVersion = "Version"
            case whatsNew = "WhatsNew"
        }
    }

    private let currentVersion: String
    private let fetch: (URL) throws -> Data

    public init(currentVersion: String, fetch: @escaping (URL) throws -> Data) {
        self.currentVersion = currentVersion
        self.fetch = fetch
    }

    public func check(updateURL: URL) -> UpdateCheckResult {
        do {
            let data = try fetch(updateURL)
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            guard let remoteVersion = payload.version ?? payload.legacyVersion else {
                return .unavailable
            }
            guard isRemoteVersion(remoteVersion, newerThan: currentVersion) else {
                return .current
            }

            let url = payload.url ?? updateURL
            return .available(UpdateInfo(version: remoteVersion, url: url))
        } catch {
            return .unavailable
        }
    }

    private func isRemoteVersion(_ remoteVersion: String, newerThan localVersion: String) -> Bool {
        remoteVersion.compare(localVersion, options: .numeric) == .orderedDescending
    }
}
