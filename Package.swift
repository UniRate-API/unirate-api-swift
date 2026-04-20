// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UniRateAPI",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "UniRateAPI",
            targets: ["UniRateAPI"]
        )
    ],
    targets: [
        .target(
            name: "UniRateAPI",
            path: "Sources/UniRateAPI"
        ),
        .testTarget(
            name: "UniRateAPITests",
            dependencies: ["UniRateAPI"],
            path: "Tests/UniRateAPITests"
        ),
    ]
)
