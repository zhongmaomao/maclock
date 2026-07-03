// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacLock",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacLock", targets: ["MacLock"]),
        .executable(name: "MacLockCheck", targets: ["MacLockCheck"])
    ],
    targets: [
        .target(name: "MacLockCore"),
        .executableTarget(
            name: "MacLock",
            dependencies: ["MacLockCore"]
        ),
        .executableTarget(
            name: "MacLockCheck",
            dependencies: ["MacLockCore"]
        )
    ]
)
