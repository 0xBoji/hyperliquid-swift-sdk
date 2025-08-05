// swift-tools-version: 6.1
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
    ],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift", from: "0.15.0"),
    ],
    targets: [
        .target(
            name: "HyperliquidSwift",
            dependencies: [
                .product(name: "libsecp256k1", package: "secp256k1.swift"),
            ],
            path: "Sources/HyperliquidSwift"
        ),
        .testTarget(
            name: "HyperliquidSwiftTests",
            dependencies: ["HyperliquidSwift"],
            path: "Tests/HyperliquidSwiftTests"
        ),
    ]
)
