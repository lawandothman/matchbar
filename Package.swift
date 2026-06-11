// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Matchbar",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0")
    ],
    targets: [
        .executableTarget(
            name: "Matchbar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [
                // Sparkle.framework is bundled into Contents/Frameworks by `make app`
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        )
    ]
)
