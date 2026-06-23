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
        .package(url: "https://github.com/whooshing-workshop/whooshing.toolbox-server.git", from: "1.2.8"),
        .package(url: "https://github.com/whooshing-workshop/whooshing.toolbox-file-storage", from: "1.0.9"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.9.1")
    ],
    targets: [
        .target(
            name: "FileStorageDriver",
            dependencies: [
                .product(name: "WhooshingServer", package: "whooshing.toolbox-server"),
                .product(name: "FileStorage", package: "whooshing.toolbox-file-storage"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "file-storage-driver-Tests",
            dependencies: [
                .product(name: "WhooshingServer", package: "whooshing.toolbox-server"),
                .target(name: "FileStorageDriver")
            ]
        )
    ]
)
