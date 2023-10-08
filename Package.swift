// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConcurrencyNetwork",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "ConcurrencyNetwork",
            targets: [
                "ConcurrencyAPI",
                "ConcurrencyDownloader",
                "ConcurrencyMonitor",
                "ConcurrencyUploader"
            ]
        )
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "ConcurrencyNetwork",
            dependencies: []
        ),
        .target(
            name: "ConcurrencyAPI",
            dependencies: [
                "ConcurrencyNetwork"
            ]
        ),
        .target(
            name: "ConcurrencyDownloader",
            dependencies: [
                "ConcurrencyNetwork"
            ]
        ),
        .target(
            name: "ConcurrencyMonitor",
            dependencies: [
                "ConcurrencyNetwork"
            ]
        ),
        .target(
            name: "ConcurrencyUploader",
            dependencies: [
                "ConcurrencyNetwork"
            ]
        ),
        .testTarget(
            name: "ConcurrencyNetworkTests",
            dependencies: [
                "ConcurrencyAPI",
                "ConcurrencyDownloader",
                "ConcurrencyMonitor",
                "ConcurrencyNetwork",
                "ConcurrencyUploader"
            ]
        ),
    ]
)
