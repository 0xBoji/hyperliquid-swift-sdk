# 🚀 Hyperliquid Swift SDK

A **complete, production-ready** Swift SDK for the Hyperliquid decentralized exchange.

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013%2B%20%7C%20macOS%2010.15%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## ✨ Features

- **🔐 Complete Trading API**: Place orders, cancel orders, manage positions
- **📊 Real-time Market Data**: Prices, order books, trade history
- **💰 Account Management**: Portfolio tracking, balance queries, user state
- **🔒 EIP-712 Signing**: Secure transaction signing with Ethereum standards
- **⚡️ Type Safety**: Full Swift type system with Codable support
- **🎯 Async/Await**: Modern Swift concurrency support
- **🌐 Multi-Environment**: Testnet and Mainnet support
- **🛡️ Enterprise Grade**: Production-ready cryptography and error handling


## ✅ Implemented Feature Checklist

- Trading
  - [x] Limit/Market orders, Modify, Cancel, Schedule cancel
  - [x] Bulk orders and Batch modify orders
- Market Data & Queries
  - [x] All mids, L2 order book, Candle snapshot
  - [x] Meta, MetaAndAssetCtxs, SpotMeta, SpotMetaAndAssetCtxs
  - [x] User/Spot state, Open/Frontend open orders, User fills (+by time)
  - [x] Funding history, User funding history, User fees
  - [x] Query order by oid/cloid, Referral state
  - [x] Perp dex list, Multi‑sig signers, Perp deploy auction status
  - [x] Sub‑accounts query (raw JSON)
- Account Management
  - [x] Update leverage, Update isolated margin, Set referrer
- Sub Accounts
  - [x] Create sub account
- Real‑time
  - [x] WebSocket subscriptions

## 🛣️ Future Features

- [ ] Map `querySubAccounts` → strong models (with nested UserState)
- [ ] More examples and docs for new APIs
- [ ] TPSL helpers and risk utilities
- [ ] CI matrix expansion (macOS versions, optional Linux build-only)
- [ ] Transfer/withdraw operations kept off by default for mobile safety (opt‑in discussion)

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/0xboji/hyperliquid-swift-sdk.git", from: "1.0.0")
]
```

## 🚀 Quick Start

```swift
import HyperliquidSwift

// Initialize client
let client = try HyperliquidClient(
    privateKeyHex: "your_private_key_here",
    environment: .testnet
)

// Get market data
let prices = try await client.getAllMids()
print("BTC Price: \(prices["BTC"] ?? 0)")

// Place a limit order
let response = try await client.limitBuy(
    coin: "ETH",
    sz: Decimal(0.1),
    px: Decimal(3000.0),
    reduceOnly: false
)
```

## 📖 API Reference

### 📊 Market Data

```swift
// Get all market prices
let prices = try await client.getAllMids()

// Get exchange metadata
let meta = try await client.getMeta()

// Get spot market metadata
let spotMeta = try await client.getSpotMeta()

// Get user state
let userState = try await client.getUserState()
```

### 💹 Trading Operations

```swift
// Place limit buy order
let buyResponse = try await client.limitBuy(
    coin: "ETH",
    sz: Decimal(0.1),
    px: Decimal(3000.0),
    reduceOnly: false
)

// Place limit sell order
let sellResponse = try await client.limitSell(
    coin: "ETH",
    sz: Decimal(0.1),
    px: Decimal(3500.0),
    reduceOnly: false
)

// Place market orders
let marketBuy = try await client.marketBuy(coin: "ETH", sz: Decimal(0.1))
let marketSell = try await client.marketSell(coin: "BTC", sz: Decimal(0.01))

// Cancel single order
let cancelResponse = try await client.cancelOrder(coin: "ETH", oid: 12345)

// Cancel all orders for a coin
let cancelAllETH = try await client.cancelAllOrders(coin: "ETH")

// Cancel all orders across all coins
let cancelAll = try await client.cancelAllOrders()

// Modify existing order
let modifyResponse = try await client.modifyOrder(
    oid: 12345,
    coin: "ETH",
    newPrice: Decimal(3200.0),
    newSize: Decimal(0.05)
)
```

### 📈 Account Information

```swift
// Get open orders
let openOrders = try await client.getOpenOrders()

// Get enhanced frontend open orders (with trigger conditions)
let frontendOrders = try await client.getFrontendOpenOrders(address: userAddress)

// Get user fills
let fills = try await client.getUserFills()

// Get user fills by time range
let recentFills = try await client.getUserFillsByTime(
    startTime: Date().addingTimeInterval(-86400), // 24 hours ago
    endTime: Date()
)

// Get user fees and trading volume
let userFees = try await client.getUserFees(address: userAddress)

// Get user funding history
let fundingHistory = try await client.getUserFunding(
    user: userAddress,
    startTime: Int(Date().addingTimeInterval(-86400).timeIntervalSince1970 * 1000),
    endTime: Int(Date().timeIntervalSince1970 * 1000)
)

// Get funding rate history for a specific coin
let btcFunding = try await client.getFundingHistory(
    coin: "BTC",
    startTime: Int(Date().addingTimeInterval(-86400).timeIntervalSince1970 * 1000)
)

// Query referral state
let referralState = try await client.queryReferralState(user: userAddress)

// Query sub accounts
let subAccounts = try await client.querySubAccounts(user: userAddress)
```

### 💸 Transfer Operations

```swift
// Transfer USDC between spot and perp wallets
let spotToPerp = try await client.usdClassTransfer(amount: Decimal(100.0), toPerp: true)
let perpToSpot = try await client.usdClassTransfer(amount: Decimal(100.0), toPerp: false)

// Transfer USDC to another address
let usdTransfer = try await client.usdTransfer(
    amount: Decimal(50.0),
    destination: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45"
)

// Transfer spot tokens
let spotTransfer = try await client.spotTransfer(
    amount: Decimal(10.0),
    destination: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
    token: "PURR:0xc4bf3f870c0e9465323c0b6ed28096c2"
)

// Transfer to/from sub account
let subAccountDeposit = try await client.subAccountTransfer(
    subAccountUser: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
    isDeposit: true,
    usd: Decimal(25.0)
)
```

## 💡 Examples

Run the included examples:

```bash
# Market data and account queries
swift run BasicUsage

# Basic trading tutorial
swift run TradingExample

# Advanced trading operations (market orders, cancel all, modify)
swift run AdvancedTradingExample

# New Info API methods (fees, funding, referrals, sub accounts)
swift run NewMethodsExample

# Transfer operations (USD, spot tokens, sub accounts)
swift run TransferExample
```

### Example Output:
```
🚀 Hyperliquid Swift SDK - Basic Usage Examples
==================================================

📈 Market Summary
=================
Active Markets: 1441

📊 Account Summary
==================
Address: 0x1234...7890
Account Value: $8.199509
Total Margin Used: $0
Positions: 0
Open Orders: 0
```

## ⚙️ Configuration

Create `Examples/config.json`:

```json
{
    "private_key": "your_private_key_hex",
    "environment": "testnet"
}
```

## 🔧 Requirements

- **iOS 13.0+** / **macOS 10.15+**
- **Swift 5.5+**
- **Xcode 13.0+**

## 📚 Dependencies

- [secp256k1.swift](https://github.com/GigaBitcoin/secp256k1.swift) - Elliptic curve cryptography
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) - Cryptographic functions

## 🏗️ Architecture

```
HyperliquidSwift/
├── Models/           # Data models and types
├── Services/         # Core services
│   ├── CryptoService.swift    # EIP-712 signing
│   ├── HTTPClient.swift       # Network layer
│   └── TradingService.swift   # Trading operations
├── Utils/            # Utilities and helpers
└── HyperliquidClient.swift    # Main client interface
```

## 🔐 Security

- **EIP-712 compliant** transaction signing
- **secp256k1** elliptic curve cryptography
- **Keccak256** hashing for Ethereum compatibility
- **Private key** never leaves your application

## 🧪 Testing

```bash
swift test
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 💬 Support

- 📖 [Documentation](https://github.com/0xboji/hyperliquid-swift-sdk/wiki)
- 🐛 [Issues](https://github.com/0xboji/hyperliquid-swift-sdk/issues)
- 💬 [Discussions](https://github.com/0xboji/hyperliquid-swift-sdk/discussions)

## 🎉 Acknowledgments

Built with ❤️ for the Hyperliquid community.

---

**Ready to trade on Hyperliquid with Swift? Let's go! 🚀**
