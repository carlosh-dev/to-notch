// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "to-notch",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "to-notch"),
        .testTarget(name: "to-notch-tests", dependencies: ["to-notch"]),
    ]
)
