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
        ),
        .library(
            name: "ConcurrencyAPI",
            targets: [
                "ConcurrencyAPI"
            ]
        ),
        .library(
            name: "ConcurrencyDownloader",
            targets: [
                "ConcurrencyDownloader"
            ]
        ),
        .library(
            name: "ConcurrencyMonitor",
            targets: [
                "ConcurrencyMonitor"
            ]
        ),
        .library(
            name: "ConcurrencyUploader",
            targets: [
                "ConcurrencyUploader"
            ]
        )
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "ConcurrencyAPI",
            dependencies: []
        ),
        .target(
            name: "ConcurrencyDownloader",
            dependencies: [
                "ConcurrencyAPI"
            ]
        ),
        .target(
            name: "ConcurrencyMonitor",
            dependencies: []
        ),
        .target(
            name: "ConcurrencyUploader",
            dependencies: [
                "ConcurrencyAPI"
            ]
        ),
        .testTarget(
            name: "ConcurrencyNetworkTests",
            dependencies: [
                "ConcurrencyAPI",
                "ConcurrencyDownloader",
                "ConcurrencyMonitor",
                "ConcurrencyUploader"
            ]
        ),
    ]
)
