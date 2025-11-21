// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MACFanControl",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MACFanControl",
            targets: ["MACFanControl"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MACFanControl",
            dependencies: ["SMCKit"],
            path: "Sources/MACFanControl"
        ),
        .target(
            name: "SMCKit",
            dependencies: [],
            path: "Sources/SMCKit"
        ),
        .testTarget(
            name: "SMCKitTests",
            dependencies: ["SMCKit"],
            path: "Tests/SMCKitTests"
        ),
        .testTarget(
            name: "MACFanControlTests",
            dependencies: ["MACFanControl", "SMCKit"],
            path: "Tests/MACFanControlTests"
        )
    ]
)
