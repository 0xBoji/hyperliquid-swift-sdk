import Foundation
import HyperliquidSwift

/// Basic usage examples for the Hyperliquid Swift SDK
class BasicUsageExamples {
    
    // MARK: - Market Data Examples
    
    /// Example: Get market data without trading
    static func marketDataExample() async throws {
        print("🔍 Market Data Example")
        print("=====================")
        
        // Create a read-only client for market data
        let client = try HyperliquidClient.marketData(environment: .testnet)
        
        // Get all available coins and their prices
        let allMids = try await client.info.getAllMids()
        print("📊 Available markets: \(allMids.count)")
        
        // Display top 5 markets by name
        let topMarkets = Array(allMids.sorted { $0.key < $1.key }.prefix(5))
        for (coin, price) in topMarkets {
            print("  \(coin): $\(price)")
        }
        
        // Get detailed order book for ETH
        if allMids.keys.contains("ETH") {
            let l2Book = try await client.info.getL2Book(coin: "ETH")
            print("\n📖 ETH Order Book:")
            print("  Coin: \(l2Book.coin)")
            print("  Levels: \(l2Book.levels.count)")
            print("  Time: \(l2Book.time)")
        }
        
        // Get metadata
        let meta = try await client.info.getMeta()
        print("\n🏛️ Perpetual Markets: \(meta.universe.count)")
        for asset in meta.universe.prefix(3) {
            print("  \(asset.name) (decimals: \(asset.szDecimals))")
        }
        
        let spotMeta = try await client.info.getSpotMeta()
        print("\n💱 Spot Markets: \(spotMeta.universe.count)")
        for asset in spotMeta.universe.prefix(3) {
            print("  \(asset.name) (canonical: \(asset.isCanonical))")
        }
    }
    
    // MARK: - Trading Examples
    
    /// Example: Basic trading operations
    static func tradingExample() async throws {
        print("\n💰 Trading Example")
        print("==================")
        
        // ⚠️ IMPORTANT: Never hardcode private keys in production!
        // This is just for demonstration purposes
        let privateKeyHex = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        
        // Create a trading client
        let client = try await HyperliquidClient.trading(
            privateKeyHex: privateKeyHex,
            environment: .testnet
        )
        
        print("🔑 Wallet Address: \(client.walletAddress ?? "Unknown")")
        
        // Get account information
        if client.canTrade {
            let accountSummary = try await client.getAccountSummary()
            print("\n💼 Account Summary:")
            print("  Account Value: $\(accountSummary.portfolioSummary.accountValue)")
            print("  Available Margin: $\(accountSummary.portfolioSummary.availableMargin)")
            print("  Active Positions: \(accountSummary.portfolioSummary.activePositions)")
            print("  Open Orders: \(accountSummary.portfolioSummary.totalOpenOrders)")
            print("  Risk Level: \(accountSummary.riskStatus.level)")
            
            // Get current positions
            let positions = try await client.exchange!.getAllPositions()
            if !positions.isEmpty {
                print("\n📈 Current Positions:")
                for position in positions {
                    if position.absoluteSize > 0 {
                        print("  \(position.coin): \(position.szi) @ $\(position.entryPx) (\(position.side))")
                        print("    Unrealized PnL: $\(position.unrealizedPnl)")
                    }
                }
            } else {
                print("\n📈 No open positions")
            }
            
            // Get open orders
            let openOrders = try await client.exchange!.getOpenOrders()
            if !openOrders.isEmpty {
                print("\n📋 Open Orders:")
                for order in openOrders {
                    print("  \(order.coin): \(order.side) \(order.sz) @ $\(order.px)")
                    print("    Order ID: \(order.oid)")
                }
            } else {
                print("\n📋 No open orders")
            }
        }
    }
    
    /// Example: Place different types of orders
    static func orderExamples() async throws {
        print("\n📝 Order Examples")
        print("=================")
        
        let privateKeyHex = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let client = try await HyperliquidClient.trading(
            privateKeyHex: privateKeyHex,
            environment: .testnet
        )
        
        guard let exchange = client.exchange else {
            print("❌ Trading not available")
            return
        }
        
        // Example 1: Limit Buy Order
        print("1️⃣ Placing limit buy order...")
        do {
            let response = try await exchange.limitBuy(
                coin: "ETH",
                sz: Decimal(0.1),
                px: Decimal(1900), // Below market price
                tif: .gtc
            )
            print("   ✅ Order placed: \(response.status)")
        } catch {
            print("   ❌ Order failed: \(error)")
        }
        
        // Example 2: Market Sell Order
        print("2️⃣ Placing market sell order...")
        do {
            let response = try await exchange.marketSell(
                coin: "ETH",
                sz: Decimal(0.05)
            )
            print("   ✅ Order placed: \(response.status)")
        } catch {
            print("   ❌ Order failed: \(error)")
        }
        
        // Example 3: Order with Client Order ID
        print("3️⃣ Placing order with client ID...")
        do {
            let cloid = "my-order-\(Int(Date().timeIntervalSince1970))"
            let response = try await exchange.limitSell(
                coin: "BTC",
                sz: Decimal(0.01),
                px: Decimal(50000), // Above market price
                cloid: cloid
            )
            print("   ✅ Order placed with CLOID \(cloid): \(response.status)")
        } catch {
            print("   ❌ Order failed: \(error)")
        }
    }
    
    // MARK: - Advanced Trading Examples
    
    /// Example: Advanced trading strategies
    static func advancedTradingExample() async throws {
        print("\n🚀 Advanced Trading Example")
        print("===========================")
        
        let privateKeyHex = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let client = try await HyperliquidClient.trading(
            privateKeyHex: privateKeyHex,
            environment: .testnet
        )
        
        guard let advancedTrading = client.advancedTrading else {
            print("❌ Advanced trading not available")
            return
        }
        
        // Example 1: Bracket Order (Entry + Stop Loss + Take Profit)
        print("1️⃣ Placing bracket order...")
        do {
            let result = try await advancedTrading.bracketOrder(
                coin: "ETH",
                side: .bid, // Long position
                size: Decimal(0.1),
                entryPrice: Decimal(2000),
                stopLoss: Decimal(1900),   // 5% stop loss
                takeProfit: Decimal(2200)  // 10% take profit
            )
            print("   ✅ Bracket order placed:")
            print("     Entry: \(result.entry.status)")
            print("     Stop Loss: \(result.stopLoss.status)")
            print("     Take Profit: \(result.takeProfit.status)")
        } catch {
            print("   ❌ Bracket order failed: \(error)")
        }
        
        // Example 2: Position Sizing Based on Risk
        print("2️⃣ Calculating position size based on risk...")
        do {
            let positionSize = try await advancedTrading.calculatePositionSize(
                coin: "BTC",
                entryPrice: Decimal(45000),
                stopLoss: Decimal(43000),
                riskPercentage: Decimal(0.02) // 2% risk
            )
            print("   📏 Calculated position size: \(positionSize) BTC")
        } catch {
            print("   ❌ Position size calculation failed: \(error)")
        }
        
        // Example 3: Iceberg Order (Large order split into chunks)
        print("3️⃣ Placing iceberg order...")
        do {
            let responses = try await advancedTrading.icebergOrder(
                coin: "ETH",
                side: .bid,
                totalSize: Decimal(1.0),    // 1 ETH total
                chunkSize: Decimal(0.2),    // 0.2 ETH per chunk
                price: Decimal(1950),
                delayBetweenOrders: 2.0     // 2 seconds between orders
            )
            print("   ✅ Iceberg order placed: \(responses.count) chunks")
        } catch {
            print("   ❌ Iceberg order failed: \(error)")
        }
    }
    
    // MARK: - WebSocket Examples
    
    /// Example: Real-time data subscriptions
    static func webSocketExample() async throws {
        print("\n📡 WebSocket Example")
        print("====================")
        
        let client = try HyperliquidClient.marketData(environment: .testnet)
        
        // Start WebSocket connection
        try await client.startWebSocket()
        print("🔌 WebSocket connected")
        
        // Subscribe to price updates for specific coins
        let priceToken = try await client.subscribeToPrices(coins: ["ETH", "BTC", "SOL"]) { prices in
            print("💰 Price Update:")
            for (coin, price) in prices.sorted(by: { $0.key < $1.key }) {
                print("  \(coin): $\(price)")
            }
        }
        
        // Subscribe to order book updates for ETH
        let bookToken = try await client.subscriptionManager?.subscribeToL2Book(coin: "ETH") { update in
            print("📖 ETH Order Book Update:")
            print("  Bids: \(update.bids.count), Asks: \(update.asks.count)")
            print("  Time: \(update.timestamp)")
        }
        
        // Subscribe to trades for BTC
        let tradesToken = try await client.subscriptionManager?.subscribeToTrades(coin: "BTC") { update in
            print("🔄 BTC Trades:")
            for trade in update.trades {
                print("  \(trade.side) \(trade.sz) @ $\(trade.px)")
            }
        }
        
        // Let it run for a bit to see updates
        print("⏳ Listening for updates for 30 seconds...")
        try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
        
        // Unsubscribe
        if let token = priceToken {
            try await client.subscriptionManager?.unsubscribe(token)
        }
        if let token = bookToken {
            try await client.subscriptionManager?.unsubscribe(token)
        }
        if let token = tradesToken {
            try await client.subscriptionManager?.unsubscribe(token)
        }
        
        await client.stopWebSocket()
        print("🔌 WebSocket disconnected")
    }
    
    // MARK: - Risk Management Examples
    
    /// Example: Risk management and portfolio analysis
    static func riskManagementExample() async throws {
        print("\n⚖️ Risk Management Example")
        print("==========================")
        
        let privateKeyHex = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let client = try await HyperliquidClient.trading(
            privateKeyHex: privateKeyHex,
            environment: .testnet
        )
        
        guard let accountManager = client.accountManager else {
            print("❌ Account manager not available")
            return
        }
        
        // Check current risk status
        let riskStatus = try await accountManager.checkRiskStatus()
        print("🎯 Risk Assessment:")
        print("  Level: \(riskStatus.level)")
        print("  Margin Utilization: \(riskStatus.marginUtilization * 100)%")
        print("  Unrealized PnL Ratio: \(riskStatus.unrealizedPnlRatio * 100)%")
        
        if !riskStatus.warnings.isEmpty {
            print("  ⚠️ Warnings:")
            for warning in riskStatus.warnings {
                print("    - \(warning)")
            }
        }
        
        // Set stop losses for all positions
        let positions = try await client.exchange!.getAllPositions()
        for position in positions {
            if position.absoluteSize > 0 {
                print("🛡️ Setting stop loss for \(position.coin)...")
                
                let stopPrice: Decimal
                if position.side == .long {
                    stopPrice = position.entryPx * Decimal(0.95) // 5% below entry
                } else {
                    stopPrice = position.entryPx * Decimal(1.05) // 5% above entry
                }
                
                do {
                    let response = try await accountManager.setStopLoss(
                        coin: position.coin,
                        stopPrice: stopPrice,
                        percentage: Decimal(1.0) // 100% of position
                    )
                    print("   ✅ Stop loss set at $\(stopPrice)")
                } catch {
                    print("   ❌ Failed to set stop loss: \(error)")
                }
            }
        }
    }
}

// MARK: - Main Example Runner

/// Run all examples
@main
struct ExampleRunner {
    static func main() async {
        print("🚀 Hyperliquid Swift SDK Examples")
        print("=================================\n")
        
        do {
            // Run market data example
            try await BasicUsageExamples.marketDataExample()
            
            // Add delay between examples
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Run trading example (commented out to avoid accidental trades)
            // try await BasicUsageExamples.tradingExample()
            // try await BasicUsageExamples.orderExamples()
            // try await BasicUsageExamples.advancedTradingExample()
            // try await BasicUsageExamples.riskManagementExample()
            
            // Run WebSocket example (commented out as it requires network)
            // try await BasicUsageExamples.webSocketExample()
            
            print("\n✅ Examples completed successfully!")
            
        } catch {
            print("\n❌ Example failed: \(error)")
        }
    }
}
