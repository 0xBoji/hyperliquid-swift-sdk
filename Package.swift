// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HyperliquidSwiftSDK",
    platforms: [
        .iOS(.v14), .macOS(.v11), .tvOS(.v14), .watchOS(.v7)
    ],
    products: [
        .library(name: "HyperliquidSwiftSDK", targets: ["HyperliquidSwiftSDK"]),
        .executable(name: "BasicAllMids", targets: ["BasicAllMids"]),
        .executable(name: "BasicPlaceOrderSketch", targets: ["BasicPlaceOrderSketch"]),
        .executable(name: "BasicMarketOrder", targets: ["BasicMarketOrder"]),
        .executable(name: "BasicPlaceOnlyOrder", targets: ["BasicPlaceOnlyOrder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.8.0"),
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift", from: "0.11.0"),
    ],
    targets: [
        .target(
            name: "HyperliquidSwiftSDK",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "libsecp256k1", package: "secp256k1.swift"),
            ]
        ),
        .executableTarget(name: "BasicAllMids", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicAllMids"),
        .executableTarget(name: "BasicPlaceOrderSketch", dependencies: [], path: "Examples/BasicPlaceOrderSketch"),
        .executableTarget(name: "BasicMarketOrder", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicMarketOrder"),
        .executableTarget(name: "BasicPlaceOnlyOrder", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicPlaceOnlyOrder"),
    ]
)


