# hyperliquid-swift-sdk

<div align="center">

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20|%20macOS%20|%20Linux-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com/0xBoji/hyperliquid-swift-sdk)

**SDK for Hyperliquid API trading with Swift.**

</div>

## ✨ Features

- 🚀 **Complete Trading API** - All core trading operations (orders, cancels, modifications)
- 📊 **Real-time WebSocket** - Live market data, user events, and order updates  
- 🔐 **Secure Cryptography** - secp256k1 + Keccak256 + EIP-712 signing
- ⚡ **Modern Swift** - Async/await, actors, type safety, and comprehensive error handling
- 📱 **Multi-platform** - iOS, macOS, and Linux support

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/0xBoji/hyperliquid-swift-sdk.git", from: "1.0.0")
]
```

Or add via Xcode: **File → Add Package Dependencies** → Enter URL

## 🚀 Quick Start

### Basic Trading Example

```swift
import HyperliquidSwift

// Create trading client
let client = try HyperliquidClient.trading(
    privateKeyHex: "your_private_key_here",
    environment: .mainnet // or .testnet
)

// Get account information
let userState = try await client.info.getUserState(address: client.walletAddress!)
print("Account Value: $\(userState.crossMarginSummary.accountValue)")

// Place a limit order
let response = try await client.exchange.limitBuy(
    coin: "ETH",
    sz: 0.1,        // 0.1 ETH
    px: 3000.0      // $3000 limit price
)
print("Order placed: \(response.status)")
```

### Market Data Example

```swift
// Get real-time prices
let prices = try await client.info.getAllMids()
print("ETH Price: $\(prices["ETH"] ?? 0)")

// Get order book
let l2Book = try await client.info.getL2Book(coin: "ETH")
print("Best Bid: $\(l2Book.levels[0][0].px)")
print("Best Ask: $\(l2Book.levels[1][0].px)")
```



## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## �� Acknowledgments

- [Hyperliquid](https://hyperliquid.xyz) for the excellent DEX platform
- [secp256k1.swift](https://github.com/GigaBitcoin/secp256k1.swift) for cryptographic operations
- Python SDK team for the reference implementation

---

<div align="center">

**Built with ❤️ for the Hyperliquid community**

[Website](https://hyperliquid.xyz) • [Discord](https://discord.gg/hyperliquid) • [Twitter](https://twitter.com/hyperliquid_xyz)

</div>
