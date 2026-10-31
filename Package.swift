// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacCommandCenter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacCommandCenter", targets: ["MacCommandCenter"])
    ],
    targets: [
        .executableTarget(
            name: "MacCommandCenter",
            path: "Sources/MacCommandCenter"
        )
    ]
)
