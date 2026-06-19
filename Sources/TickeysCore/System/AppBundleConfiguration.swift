import Foundation

public struct AppBundleConfiguration: Equatable, Sendable {
    public static let `default` = AppBundleConfiguration(
        productName: "Tickeys-Swift",
        bundleIdentifier: "github.zjjfly.Tickeys-Swift",
        executableName: "Tickeys-Swift",
        iconFileName: "tickeys-swift",
        version: "0.1.0",
        isAgentApp: true,
        prohibitsMultipleInstances: true
    )

    public let productName: String
    public let bundleIdentifier: String
    public let executableName: String
    public let iconFileName: String
    public let version: String
    public let isAgentApp: Bool
    public let prohibitsMultipleInstances: Bool

    public init(
        productName: String,
        bundleIdentifier: String,
        executableName: String,
        iconFileName: String,
        version: String,
        isAgentApp: Bool,
        prohibitsMultipleInstances: Bool
    ) {
        self.productName = productName
        self.bundleIdentifier = bundleIdentifier
        self.executableName = executableName
        self.iconFileName = iconFileName
        self.version = version
        self.isAgentApp = isAgentApp
        self.prohibitsMultipleInstances = prohibitsMultipleInstances
    }
}

public struct AppBundleInfoPlist: Equatable, Sendable {
    public let configuration: AppBundleConfiguration

    public init(configuration: AppBundleConfiguration) {
        self.configuration = configuration
    }

    public var dictionary: [String: Any] {
        [
            "CFBundleDevelopmentRegion": "English",
            "CFBundleExecutable": configuration.executableName,
            "CFBundleIconFile": configuration.iconFileName,
            "CFBundleIdentifier": configuration.bundleIdentifier,
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleLocalizations": ["Base", "zh-Hans"],
            "CFBundleName": configuration.productName,
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": configuration.version,
            "CFBundleVersion": configuration.version,
            "LSMultipleInstancesProhibited": configuration.prohibitsMultipleInstances,
            "LSUIElement": configuration.isAgentApp,
            "NSHighResolutionCapable": true
        ]
    }
}
