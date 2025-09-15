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
        .executable(name: "BasicOrderCancel", targets: ["BasicOrderCancel"]),
        .executable(name: "BasicUserFills", targets: ["BasicUserFills"]),
        .executable(name: "BasicOpenOrders", targets: ["BasicOpenOrders"]),
        .executable(name: "BasicFundingHistory", targets: ["BasicFundingHistory"]),
        .executable(name: "BasicL2Snapshot", targets: ["BasicL2Snapshot"]),
        .executable(name: "BasicCandlesSnapshot", targets: ["BasicCandlesSnapshot"]),
        .executable(name: "BasicUserFundingHistory", targets: ["BasicUserFundingHistory"]),
        .executable(name: "BasicMetaAndAssetCtxs", targets: ["BasicMetaAndAssetCtxs"]),
        .executable(name: "BasicOrderStatus", targets: ["BasicOrderStatus"]),
        .executable(name: "BasicUserFillsByTime", targets: ["BasicUserFillsByTime"]),
        .executable(name: "BasicUpdateLeverage", targets: ["BasicUpdateLeverage"]),
        .executable(name: "BasicUpdateIsolatedMargin", targets: ["BasicUpdateIsolatedMargin"]),
        .executable(name: "BasicScheduleCancel", targets: ["BasicScheduleCancel"]),
        .executable(name: "BasicHistoric  alOrders", targets: ["BasicHistoricalOrders"]),





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
        .executableTarget(name: "BasicOrderCancel", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicOrderCancel"),
        .executableTarget(name: "BasicUserFills", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicUserFills"),
        .executableTarget(name: "BasicOpenOrders", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicOpenOrders"),
        .executableTarget(name: "BasicFundingHistory", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicFundingHistory"),
        .executableTarget(name: "BasicL2Snapshot", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicL2Snapshot"),
        .executableTarget(name: "BasicCandlesSnapshot", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicCandlesSnapshot"),
        .executableTarget(name: "BasicUserFundingHistory", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicUserFundingHistory"),
        .executableTarget(name: "BasicMetaAndAssetCtxs", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicMetaAndAssetCtxs"),
        .executableTarget(name: "BasicOrderStatus", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicOrderStatus"),
        .executableTarget(name: "BasicUserFillsByTime", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicUserFillsByTime"),
        .executableTarget(name: "BasicUpdateLeverage", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicUpdateLeverage"),
        .executableTarget(name: "BasicUpdateIsolatedMargin", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicUpdateIsolatedMargin"),
        .executableTarget(name: "BasicScheduleCancel", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicScheduleCancel"),
        .executableTarget(name: "BasicHistoricalOrders", dependencies: ["HyperliquidSwiftSDK"], path: "Examples/BasicHistoricalOrders"),













    ]
)


