# Hyperliquid Swift SDK Examples

This directory contains comprehensive examples demonstrating how to use the Hyperliquid Swift SDK. Each example corresponds to similar functionality in the Python SDK examples.

## 📁 Example Files

### Core Trading Examples
- **`BasicUsage.swift`** - Basic SDK setup and simple operations
- **`TradingExample.swift`** - Limit orders, market orders, cancellations
- **`AdvancedTradingExample.swift`** - Advanced trading strategies and bulk operations

### Transfer & Account Management
- **`TransferExample.swift`** - USD transfers, spot transfers, sub-account operations

### New Advanced Features
- **`ConvertToMultiSigExample.swift`** - Convert account to multi-signature user
- **`UseBigBlocksExample.swift`** - Enable/disable big blocks for performance
- **`BuilderFeeExample.swift`** - Approve builder fees and route orders through builders
- **`MultiSigOrderExample.swift`** - Execute orders using multi-signature authentication

### Utility
- **`ExampleUtils.swift`** - Shared utilities for configuration and setup
- **`config.json.example`** - Example configuration file

## 🚀 Getting Started

### 1. Configuration Setup

Copy the example configuration file and add your credentials:

```bash
cp config.json.example config.json
```

Edit `config.json` with your wallet details:

```json
{
  "private_key": "0x...",
  "testnet": true,
  "wallet_address": "0x..."
}
```

### 2. Running Examples

Each example can be run independently. Here are some common patterns:

#### Basic Trading
```swift
// Run basic usage example
swift run BasicUsage

// Run trading example
swift run TradingExample
```

#### Advanced Features
```swift
// Convert to multi-sig user (PERMANENT - use with caution!)
swift run ConvertToMultiSigExample

// Configure big blocks
swift run UseBigBlocksExample

// Setup builder fees
swift run BuilderFeeExample
```

## 📋 Example Descriptions

### ConvertToMultiSigExample.swift
Demonstrates how to convert a regular account to a multi-signature user account. This is a **permanent operation** that requires multiple signatures for future transactions.

**Key Features:**
- Account conversion to multi-sig
- Authorized user management
- Threshold configuration

**⚠️ Warning:** This is irreversible. Only use on testnet unless you fully understand the implications.

### UseBigBlocksExample.swift
Shows how to enable/disable big blocks for improved performance in high-frequency trading scenarios.

**Key Features:**
- Enable big blocks for better throughput
- Disable big blocks when not needed
- Performance optimization

### BuilderFeeExample.swift
Demonstrates how to approve builder fees and route orders through specific builders for potentially better execution.

**Key Features:**
- Builder fee approval
- Order routing through builders
- Fee rate configuration

### MultiSigOrderExample.swift
Shows how to execute orders using multi-signature authentication, requiring multiple authorized signatures.

**Key Features:**
- Multi-signature order execution
- Signature collection and validation
- Threshold-based authorization

**Note:** This example uses placeholder signatures. In production, you need real signatures from authorized wallets.

## 🔧 Development Tips

### Error Handling
All examples include comprehensive error handling:

```swift
do {
    let result = try await client.someOperation()
    print("✅ Success: \(result)")
} catch {
    print("❌ Error: \(error)")
}
```

### Testnet vs Mainnet
Always test on testnet first:

```swift
let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
```

### Configuration Management
Use the shared `ExampleUtils` for consistent setup:

```swift
let config = try ExampleUtils.loadConfig()
let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
```

## 🧪 Testing

The examples are designed to work with the test suite. Run tests to verify functionality:

```bash
swift test
```

## 📚 Related Documentation

- **Main README**: `../README.md` - SDK overview and installation
- **Feature Comparison**: `../FEATURE_COMPARISON.md` - Python vs Swift feature parity
- **API Documentation**: Generated docs for detailed API reference

## 🤝 Contributing

When adding new examples:

1. Follow the existing naming convention
2. Include comprehensive error handling
3. Add detailed comments explaining the functionality
4. Update this README with the new example
5. Ensure the example works on testnet

## ⚠️ Important Notes

- **Always test on testnet first** before using real funds
- **Multi-sig conversion is permanent** - cannot be easily reversed
- **Builder fees** require main wallet permissions, not agent wallets
- **Keep your private keys secure** and never commit them to version control

## 📞 Support

If you encounter issues with the examples:

1. Check the main SDK documentation
2. Verify your configuration is correct
3. Ensure you're using testnet for testing
4. Review the error messages for specific guidance
