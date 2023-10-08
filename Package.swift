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
                "API",
                "Downloader",
                "Monitor",
                "Uploader"
            ]
        ),
        .library(
            name: "ConcurrencyAPI",
            targets: [
                "API"
            ]
        ),
        .library(
            name: "ConcurrencyDownloader",
            targets: [
                "Downloader"
            ]
        ),
        .library(
            name: "ConcurrencyMonitor",
            targets: [
                "Monitor"
            ]
        ),
        .library(
            name: "ConcurrencyUploader",
            targets: [
                "Uploader"
            ]
        ),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "Common",
            dependencies: []
        ),
        .target(
            name: "API",
            dependencies: [
                "Common"
            ]
        ),
        .target(
            name: "Downloader",
            dependencies: [
                "Common"
            ]
        ),
        .target(
            name: "Monitor",
            dependencies: [
                "Common"
            ]
        ),
        .target(
            name: "Uploader",
            dependencies: [
                "Common"
            ]
        ),
        .testTarget(
            name: "ConcurrencyNetworkTests",
            dependencies: [
                "API",
                "Downloader",
                "Monitor",
                "Uploader"
            ]
        ),
    ]
)
