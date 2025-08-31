// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hyperliquid-swift-sdk",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "HyperliquidSwift",
            targets: ["HyperliquidSwift"]
        ),
        .executable(
            name: "BasicUsage",
            targets: ["BasicUsage"]
        ),
        .executable(
            name: "TradingExample",
            targets: ["TradingExample"]
        ),
        .executable(
            name: "AdvancedTradingExample",
            targets: ["AdvancedTradingExample"]
        ),
        .executable(
            name: "MarketMakingExample",
            targets: ["MarketMakingExample"]
        ),

    ],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift", exact: "0.16.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
    ],
    targets: [
        .target(
            name: "HyperliquidSwift",
            dependencies: [
                .product(name: "secp256k1", package: "secp256k1.swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
            ],
            path: "Sources/HyperliquidSwift"
        ),
        .executableTarget(
            name: "BasicUsage",
            dependencies: ["HyperliquidSwift"],
            path: "Examples",
            sources: ["BasicUsage.swift", "ExampleUtils.swift"]
        ),
        .executableTarget(
            name: "TradingExample",
            dependencies: ["HyperliquidSwift"],
            path: "Examples",
            sources: ["TradingExample.swift"]
        ),
        .executableTarget(
            name: "AdvancedTradingExample",
            dependencies: ["HyperliquidSwift"],
            path: "Examples",
            sources: ["AdvancedTradingExample.swift"]
        ),
        .executableTarget(
            name: "MarketMakingExample",
            dependencies: ["HyperliquidSwift"],
            path: "Examples",
            sources: ["MarketMakingExample.swift"]
        ),

        .testTarget(
            name: "HyperliquidSwiftTests",
            dependencies: ["HyperliquidSwift"],
            path: "Tests/HyperliquidSwiftTests",
            resources: [
                .copy("../Resources")
            ]
        ),
    ]
)
