import Foundation
import HyperliquidSwift

/// Example demonstrating trading functionality
/// This shows how to use the Hyperliquid Swift SDK for trading operations
@main
struct TradingExample {
    static func main() async {
        print("🚀 Hyperliquid Swift SDK - Trading Example")
        print("==========================================")
        
        do {
            // Initialize client for testnet (read-only mode)
            let client = try HyperliquidClient(environment: .testnet)
            
            print("\n📊 Market Data Examples:")
            await demonstrateMarketData(client: client)
            
            print("\n💰 Trading Examples (Simulated):")
            await demonstrateTradingConcepts()
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    /// Demonstrate market data functionality
    static func demonstrateMarketData(client: HyperliquidClient) async {
        do {
            // Get all mids (current prices)
            print("📈 Fetching current prices...")
            let allMids = try await client.getAllMids()
            
            // Show first few prices
            let limitedMids = Array(allMids.prefix(5))
            for (symbol, price) in limitedMids {
                print("   \(symbol): $\(price)")
            }
            
            // Get meta information
            print("\n📋 Fetching market metadata...")
            let meta = try await client.getMeta()
            print("   Available assets: \(meta.universe.count)")
            
            // Show first few assets
            let limitedAssets = Array(meta.universe.prefix(3))
            for asset in limitedAssets {
                print("   - \(asset.name): \(asset.szDecimals) decimals")
            }
            
        } catch {
            print("❌ Market data error: \(error)")
        }
    }
    
    /// Demonstrate trading concepts (without actual trading)
    static func demonstrateTradingConcepts() async {
        print("📚 Trading Concepts Overview:")
        print("")
        
        print("🔑 Authentication Required:")
        print("   To trade, initialize client with private key:")
        print("   let client = try HyperliquidClient(")
        print("       environment: .testnet,")
        print("       privateKey: \"your_private_key_hex\"")
        print("   )")
        print("")
        
        print("📝 Order Types:")
        print("   • Limit Orders: Specify exact price")
        print("   • Market Orders: Execute at current market price")
        print("   • Reduce-Only: Only reduce existing position")
        print("")
        
        print("🛒 Example Order Placement:")
        print("   // Place a limit buy order")
        print("   let response = try await client.limitBuy(")
        print("       coin: \"BTC\",")
        print("       sz: 0.01,")
        print("       px: 45000.0")
        print("   )")
        print("")
        
        print("❌ Order Cancellation:")
        print("   // Cancel order by ID")
        print("   try await client.cancelOrder(")
        print("       coin: \"BTC\",")
        print("       oid: orderID")
        print("   )")
        print("")
        
        print("🔄 Order Modification:")
        print("   // Modify existing order")
        print("   let newOrder = OrderRequest(")
        print("       asset: \"BTC\",")
        print("       isBuy: true,")
        print("       limitPx: 46000.0,")
        print("       sz: 0.02")
        print("   )")
        print("   try await client.modifyOrder(oid: orderID, order: newOrder)")
        print("")
        
        print("⚠️  Risk Management:")
        print("   • Always use testnet first")
        print("   • Start with small amounts")
        print("   • Implement proper error handling")
        print("   • Monitor positions actively")
        print("")
        
        print("🔐 Security Best Practices:")
        print("   • Never hardcode private keys")
        print("   • Use environment variables")
        print("   • Implement proper key management")
        print("   • Regular security audits")
        print("")
        
        await simulateOrderFlow()
    }
    
    /// Simulate a complete order flow
    static func simulateOrderFlow() async {
        print("🎯 Simulated Order Flow:")
        print("========================")
        
        // Simulate order placement
        print("1️⃣ Placing limit buy order...")
        await simulateDelay(0.5)
        print("   ✅ Order placed: ID #12345")
        print("   📊 BTC Limit Buy: 0.01 @ $45,000")
        
        // Simulate order status check
        print("\n2️⃣ Checking order status...")
        await simulateDelay(0.3)
        print("   📋 Status: Open (Waiting for fill)")
        
        // Simulate partial fill
        print("\n3️⃣ Partial fill received...")
        await simulateDelay(0.7)
        print("   💰 Filled: 0.005 BTC @ $45,000")
        print("   📊 Remaining: 0.005 BTC")
        
        // Simulate order modification
        print("\n4️⃣ Modifying remaining order...")
        await simulateDelay(0.4)
        print("   🔄 New price: $44,500")
        print("   ✅ Order modified successfully")
        
        // Simulate complete fill
        print("\n5️⃣ Order completely filled...")
        await simulateDelay(0.6)
        print("   🎉 Filled: 0.005 BTC @ $44,500")
        print("   ✅ Order completed")
        
        print("\n📈 Final Position:")
        print("   💰 Total BTC acquired: 0.01")
        print("   💵 Average price: $44,750")
        print("   📊 Total cost: $447.50")
    }
    
    /// Simulate network delay
    static func simulateDelay(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - Helper Extensions

extension HyperliquidClient {
    /// Convenience method for limit buy orders
    func limitBuy(coin: String, sz: Double, px: Double) async throws {
        // This would call the actual trading service when implemented
        print("🛒 Limit Buy: \(sz) \(coin) @ $\(px)")
    }
    
    /// Convenience method for limit sell orders  
    func limitSell(coin: String, sz: Double, px: Double) async throws {
        // This would call the actual trading service when implemented
        print("🏷️ Limit Sell: \(sz) \(coin) @ $\(px)")
    }
    
    /// Convenience method for market buy orders
    func marketBuy(coin: String, sz: Double) async throws {
        // This would call the actual trading service when implemented
        print("🛒 Market Buy: \(sz) \(coin)")
    }
    
    /// Convenience method for market sell orders
    func marketSell(coin: String, sz: Double) async throws {
        // This would call the actual trading service when implemented
        print("🏷️ Market Sell: \(sz) \(coin)")
    }
}
