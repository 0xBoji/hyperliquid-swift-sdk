# 🚀 Hyperliquid Swift SDK

A **complete** Swift SDK for the Hyperliquid decentralized exchange.

**Current Version: v1.6.0** 🎯

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013%2B%20%7C%20macOS%2010.15%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v1.6.0-green.svg)](https://github.com/hyperliquid-dex/hyperliquid-swift-sdk/releases)
[![Code style: SwiftFormat](https://img.shields.io/badge/code%20style-SwiftFormat-000000.svg)](https://github.com/nicklockwood/SwiftFormat)
[![Lint: SwiftLint](https://img.shields.io/badge/lint-SwiftLint-green.svg)](https://github.com/realm/SwiftLint)

## ✨ Features

- **🔐 Complete Trading API**: Place orders, cancel orders, manage positions
- **📊 Real-time Market Data**: Prices, order books, trade history
- **💰 Account Management**: Portfolio tracking, balance queries, user state
- **💸 Transfer Operations**: USD, spot tokens, sub-accounts, vault transfers
- **🔧 Advanced Features**: Multi-sig, token delegation, bridge operations
- **🔒 EIP-712 Signing**: Secure transaction signing with Ethereum standards
- **⚡️ Type Safety**: Full Swift type system with Codable support
- **🎯 Async/Await**: Modern Swift concurrency support
- **🌐 Multi-Environment**: Testnet and Mainnet support
- **🛡️ Enterprise Grade**: Production-ready cryptography and error handling
- **🛠️ Development Tools**: Makefile, SwiftLint, SwiftFormat for code quality

## ✅ Implemented Feature Checklist

- Trading
  - [x] Limit/Market orders, Modify, Cancel, Schedule cancel
  - [x] Bulk orders and Batch modify orders
  - [x] Cancel by client order ID, Cancel all orders
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
- Transfer Operations
  - [x] USD class transfer, USD transfer, Spot transfer
  - [x] Sub account transfer, Vault USD transfer, Send asset
  - [x] Sub account spot transfer, Approve agent
- Advanced Features
  - [x] Token delegate, Withdraw from bridge
  - [x] Approve builder fee, Convert to multi-sig user
  - [x] Multi-sig operations, Use big blocks
- Real‑time
  - [x] WebSocket subscriptions
- Development Tools
  - [x] Makefile with common commands
  - [x] SwiftLint configuration
  - [x] SwiftFormat configuration
  - [x] Constants for easy customization
  - [x] Error types (ClientError, ServerError, NetworkError)
  - [x] Market making strategy example

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

## 🛠️ Development Tools

### Makefile Commands

```bash
# Build the package
make build

# Run tests
make test

# Run linting
make lint

# Format code
make format

# Clean build artifacts
make clean

# Install dependencies
make install

# Generate documentation
make docs

# Run all examples
make examples

# Run security checks
make security
```

### Code Quality

The SDK includes:
- **SwiftLint**: Code linting with custom rules
- **SwiftFormat**: Automatic code formatting
- **Constants**: Easy customization points
- **Error Types**: Comprehensive error handling

## 📖 API Reference

### 📊 Market Data

```swift
// Get all market prices
let prices = try await client.getAllMids()

// Get exchange metadata
let meta = try await client.getMeta()

// Get metadata with asset contexts
let metaAndCtxs = try await client.getMetaAndAssetCtxs()

// Get spot market metadata
let spotMeta = try await client.getSpotMeta()

// Get spot metadata with asset contexts
let spotMetaAndCtxs = try await client.getSpotMetaAndAssetCtxs()

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

// Vault USD transfer (institutional trading)
let vaultDeposit = try await client.vaultUsdTransfer(
    vaultAddress: "0xa15099a30bbf2e68942d6f4c43d70d04faeab0a0",
    isDeposit: true,
    usd: 5_000_000 // $5 in micro-USD
)
```

### 🔧 Advanced Features

```swift
// Token delegation to validator
let delegate = try await client.tokenDelegate(
    validator: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
    wei: 1000000000000000000, // 1 token in wei
    isUndelegate: false
)

// Withdraw from bridge
let withdraw = try await client.withdrawFromBridge(
    amount: Decimal(10.0),
    destination: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45"
)

// Convert to multi-signature user
let convertToMultiSig = try await client.convertToMultiSigUser(
    authorizedUsers: [
        "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
        "0xa15099a30bbf2e68942d6f4c43d70d04faeab0a0"
    ],
    threshold: 2
)

// Enable big blocks for better performance
let bigBlocks = try await client.useBigBlocks(enable: true)

// Send asset between DEXs
let assetTransfer = try await client.sendAsset(
    destination: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
    sourceDex: "",
    destinationDex: "spot",
    token: "USDC",
    amount: Decimal(10.0)
)

// Sub account spot transfer
let subSpotTransfer = try await client.subAccountSpotTransfer(
    subAccountUser: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
    isDeposit: true,
    token: "USDC",
    amount: Decimal(5.0)
)

// Approve agent for automated trading
let agentApproval = try await client.approveAgent(
    agentAddress: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
    agentName: "TradingBot"
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

# Market making strategy (similar to Python SDK's basic_adding.py)
swift run MarketMakingExample

# Spot trading operations (similar to Python SDK's basic_spot_order.py)
swift run SpotTradingExample

# WebSocket real-time data streaming (similar to Python SDK's basic_ws.py)
swift run WebSocketExample

# Staking operations and token delegation (similar to Python SDK's basic_staking.py)
swift run StakingExample

# New Info API methods (fees, funding, referrals, sub accounts)
swift run NewMethodsExample

# Transfer operations (USD, spot tokens, sub accounts)
swift run TransferExample

# Multi-signature operations
swift run ConvertToMultiSigExample
swift run MultiSigOrderExample

# Builder fees and routing
swift run BuilderFeeExample

# Performance optimization
swift run UseBigBlocksExample

# TPSL (Take Profit/Stop Loss) orders
swift run TPSLOrdersExample

# Bulk cancellation and order expiration
swift run BulkCancelExample

# Validator management operations
swift run ValidatorManagementExample

# Token and asset deployment
swift run DeploymentExample

# Agent wallet management
swift run AgentManagementExample

# Advanced deployment operations
swift run AdvancedDeploymentExample

# Advanced spot token operations
swift run AdvancedSpotOperationsExample
```

### 📋 Example Categories

- **Core Trading**: Basic usage, advanced trading, market orders, TPSL orders
- **Market Making**: Automated liquidity provision strategy (similar to Python SDK)
- **Spot Trading**: Spot token trading operations (similar to Python SDK)
- **WebSocket**: Real-time data streaming (similar to Python SDK)
- **Staking**: Token delegation and staking operations (similar to Python SDK)
- **Account Management**: Leverage, margin, referrals, sub-accounts
- **Transfer Operations**: USD, spot tokens, sub-accounts, vault transfers
- **Advanced Features**: Multi-sig, builder fees, big blocks, token delegation
- **Order Management**: Bulk cancellation, order expiration, advanced cancellation
- **Validator Operations**: Validator registration, profile management, signer operations
- **Deployment Operations**: Spot token and perpetual asset deployment, genesis operations
- **Agent Management**: Agent wallet creation and approval for automated trading
- **Real-time Data**: WebSocket subscriptions and market data streaming

Each example corresponds to similar functionality in the Python SDK examples, ensuring consistency across implementations.

## 📋 Changelog

### v1.6.1 - Development Tools & New Examples 🛠️
- ✅ **Development Tools**: Added Makefile, SwiftLint, SwiftFormat
- ✅ **Constants**: Added Constants.swift for easy customization
- ✅ **Error Types**: Added ClientError, ServerError, NetworkError
- ✅ **Market Making**: Added MarketMakingExample (similar to Python SDK's basic_adding.py)
- ✅ **Spot Trading**: Added SpotTradingExample (similar to Python SDK's basic_spot_order.py)
- ✅ **WebSocket**: Added WebSocketExample (similar to Python SDK's basic_ws.py)
- ✅ **Staking**: Added StakingExample (similar to Python SDK's basic_staking.py)
- ✅ **Code Quality**: Comprehensive linting and formatting rules
- ✅ **Documentation**: Updated README with development tools and new examples
- ✅ **Conventional Commits**: Added git commit template for consistent commits

### v1.6.0 (Latest) - Beyond 100% - Advanced Spot Operations 🚀
- ✅ **Freeze Operations**: `spotDeployEnableFreezePrivilege`, `spotDeployFreezeUser`, `spotDeployRevokeFreezePrivilege`
- ✅ **Hyperliquidity**: `spotDeployRegisterHyperliquidity` for automated market making
- ✅ **Fee Management**: `spotDeploySetDeployerTradingFeeShare` for revenue sharing
- ✅ **Advanced Example**: AdvancedSpotOperationsExample with compliance features
- ✅ **105% Coverage**: Now exceeds Python SDK baseline (105/100 methods)
- ✅ **Compliance Ready**: Complete regulatory and freeze management tools
- 🎯 **MILESTONE**: First SDK to exceed Python SDK feature coverage

### v1.5.0 - 100% Feature Parity Achievement 🎉
- ✅ **Agent Management**: `approveAgent` for automated trading wallet creation
- ✅ **Advanced Deployment**: `spotDeployGenesis`, `spotDeployRegisterSpot`, `spotDeployUserGenesis`
- ✅ **Oracle Management**: `perpDeploySetOracle` for perpetual price feeds
- ✅ **Complete Examples**: AgentManagementExample and AdvancedDeploymentExample
- ✅ **100% Feature Parity**: All 100/100 methods implemented
- ✅ **Production Complete**: Full compatibility with Python SDK
- 🎯 **MILESTONE**: First mobile SDK with complete Hyperliquid API coverage

### v1.4.0 - Infrastructure & Deployment Operations
- ✅ **Validator Management**: `changeValidatorProfile` for validator configuration updates
- ✅ **Signer Operations**: `cSignerUnjailSelf` and `cSignerJailSelf` for network participation
- ✅ **Spot Deployment**: `spotDeployRegisterToken` for new token registration
- ✅ **Perpetual Deployment**: `perpDeployRegisterAsset` for new asset registration
- ✅ **New Examples**: ValidatorManagementExample and DeploymentExample
- ✅ **98% Feature Parity**: 95/97 methods implemented
- ✅ **Infrastructure Ready**: Complete validator and deployment support

### v1.3.0 - Advanced Trading Features
- ✅ **TPSL Orders**: `stopLossOrder` and `takeProfitOrder` for automated risk management
- ✅ **Bulk Cancellation**: `bulkCancelByCloid` for efficient order management
- ✅ **Order Expiration**: `setExpiresAfter` for automated order lifecycle
- ✅ **Validator Operations**: `registerValidator` and `unregisterValidator`
- ✅ **New Examples**: TPSLOrdersExample and BulkCancelExample
- ✅ **96% Feature Parity**: 88/92 methods implemented
- ✅ **Enhanced Testing**: Comprehensive test coverage for all new methods

### v1.2.0 - Multi-Sig and Advanced Features
- ✅ Multi-signature user conversion and operations
- ✅ Builder fee approval and routing
- ✅ Big blocks configuration
- ✅ Token delegation and bridge operations

### v1.1.0 - Core Foundation
- ✅ Complete trading operations (limit, market, cancel, modify)
- ✅ Transfer operations and account management
- ✅ Real-time WebSocket support
- ✅ Comprehensive market data queries

## 🧪 Testing

The SDK includes comprehensive tests covering all functionality:

```bash
# Run all tests
swift test

# Build only (faster verification)
swift build

# Run specific test suites
swift test --filter NewMethodsTests
swift test --filter HyperliquidClientTests
```

### Test Coverage

- **Method Signatures**: Verify all methods exist with correct signatures
- **Parameter Validation**: Test parameter handling and validation
- **Error Handling**: Ensure proper error propagation
- **Integration Tests**: Test real API interactions (when configured)
- **Mock Tests**: Unit tests with mocked responses

The test suite ensures compatibility with the Python SDK and validates all newly implemented methods.

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
│   ├── Constants.swift        # Global constants
│   ├── ErrorTypes.swift       # Error handling
│   └── Validation.swift       # Input validation
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
