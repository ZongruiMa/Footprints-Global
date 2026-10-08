// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TravelCore",
    platforms: [.macOS(.v13)],
    products: [.library(name: "TravelCore", targets: ["TravelCore"])],
    targets: [
        .target(name: "TravelCore", path: "Core"),
        .testTarget(name: "TravelCoreTests", dependencies: ["TravelCore"], path: "Tests", resources: [.copy("Fixtures")])
    ]
)
