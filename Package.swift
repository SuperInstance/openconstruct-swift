// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenConstruct",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "OpenConstruct", targets: ["OpenConstruct"]),
    ],
    targets: [
        .target(name: "OpenConstruct", path: "Sources/OpenConstruct"),
        .testTarget(name: "OpenConstructTests", dependencies: ["OpenConstruct"], path: "Tests/OpenConstructTests"),
    ]
)
