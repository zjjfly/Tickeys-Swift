// swift-tools-version: 5.10.0

import PackageDescription

let package = Package(
    name: "TickeysSwift",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "TickeysCore", targets: ["TickeysCore"]),
        .executable(name: "Tickeys-Swift", targets: ["TickeysApp"]),
        .executable(name: "TickeysCoreTestRunner", targets: ["TickeysCoreTestRunner"])
    ],
    targets: [
        .target(name: "TickeysCore"),
        .executableTarget(
            name: "TickeysApp",
            dependencies: ["TickeysCore"]
        ),
        .executableTarget(
            name: "TickeysCoreTestRunner",
            dependencies: ["TickeysCore"]
        )
    ]
)
