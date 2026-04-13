// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Amplibre",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "Amplibre", targets: ["Amplibre"]),
        .library(name: "AmplibreCore", targets: ["AmplibreCore"]),
        .library(name: "SkinEngine", targets: ["SkinEngine"]),
        .library(name: "AudioCore", targets: ["AudioCore"]),
        .library(name: "AmplibreUI", targets: ["AmplibreUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.15.0"),
    ],
    targets: [
        // MARK: - App

        .executableTarget(
            name: "Amplibre",
            dependencies: [
                "AmplibreCore",
                "SkinEngine",
                "AudioCore",
                "AmplibreUI",
            ],
            path: "App",
            exclude: ["Info.plist", "Amplibre.entitlements"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .enableExperimentalFeature("DefaultIsolation(MainActor.self)"),
            ]
        ),

        // MARK: - AmplibreCore

        .target(
            name: "AmplibreCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ],
            path: "Sources/AmplibreCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .enableExperimentalFeature("DefaultIsolation(MainActor.self)"),
            ]
        ),

        // MARK: - SkinEngine

        .target(
            name: "SkinEngine",
            dependencies: [
                "AmplibreCore",
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            path: "Sources/SkinEngine",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .enableExperimentalFeature("DefaultIsolation(MainActor.self)"),
            ]
        ),

        // MARK: - AudioCore

        .target(
            name: "AudioCore",
            dependencies: [
                "AmplibreCore",
            ],
            path: "Sources/AudioCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .enableExperimentalFeature("DefaultIsolation(MainActor.self)"),
            ]
        ),

        // MARK: - AmplibreUI

        .target(
            name: "AmplibreUI",
            dependencies: [
                "AmplibreCore",
                "SkinEngine",
                "AudioCore",
            ],
            path: "Sources/AmplibreUI",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .enableExperimentalFeature("DefaultIsolation(MainActor.self)"),
            ]
        ),

        // MARK: - Tests

        .testTarget(
            name: "AmplibreCoreTests",
            dependencies: ["AmplibreCore"],
            path: "Tests/AmplibreCoreTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .enableExperimentalFeature("DefaultIsolation(MainActor.self)"),
            ]
        ),

        .testTarget(
            name: "SkinEngineTests",
            dependencies: [
                "SkinEngine",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/SkinEngineTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .enableExperimentalFeature("DefaultIsolation(MainActor.self)"),
            ]
        ),

        .testTarget(
            name: "AmplibreUITests",
            dependencies: [
                "AmplibreUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/AmplibreUITests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .enableExperimentalFeature("DefaultIsolation(MainActor.self)"),
            ]
        ),
    ]
)
