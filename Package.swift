// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "whooshing.driver-file-storage",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library( name: "FileStorageDriver", targets: ["FileStorageDriver"] )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.9.1"),
        .package(url: "https://github.com/whooshing-workshop/whooshing.nexus", from: "1.0.0"),
        .package(url: "https://github.com/whooshing-workshop/whooshing.toolbox-file-storage", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "FileStorageDriver",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Nexus", package: "whooshing.nexus"),
                .product(name: "FileStorage", package: "whooshing.toolbox-file-storage")
            ]
        ),
        .testTarget(
            name: "file-storage-driver-Tests",
            dependencies: [
                .target(name: "FileStorageDriver"),
                .product(name: "Nexus", package: "whooshing.nexus")
            ]
        )
    ]
)
