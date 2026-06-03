// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CCMonitor",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "CCMonitor",
            path: "Sources/CCMonitor"
        )
    ]
)
