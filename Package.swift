// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnakeMac",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "SnakeMac", targets: ["SnakeMac"])],
    targets: [
        .target(name: "SnakeCore"),
        .executableTarget(name: "SnakeMac", dependencies: ["SnakeCore"])
    ]
)
