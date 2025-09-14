import Foundation
import HyperliquidSwiftSDK

@main
struct BasicOrderCancelExample {
    static func main() async {
        print("🚀 Hyperliquid Swift SDK - Basic Order Cancel Example")
        print("=====================================================")
        
        do {
            // Initialize info client (no private key needed for market data)
            let baseURL = URL(string: "https://api.hyperliquid-testnet.xyz")!
            let info = InfoClient(
                config: InfoClientConfig(baseURL: baseURL)
            )
            
            print("\n📊 Market Data")
            print("==============")
            
            // Get current market prices
            let mids = try await info.allMids()
            print("Available markets: \(mids.count)")
            
            // Use ETH for this example
            guard let ethPrice = mids["ETH"], let price = Double(ethPrice) else {
                print("❌ ETH price not found")
                return
            }
            
            print("ETH current price: $\(String(format: "%.2f", price))")
            
            print("\n📈 Order Management Demo")
            print("=======================")
            
            // Demo the order structure that would be created
            let clientOrderId = "swift-sdk-\(Int(Date().timeIntervalSince1970))"
            let orderPrice = price * 0.95 // 5% below market price
            let orderSize = 0.01 // Small size for testing
            
            print("Demo order structure:")
            print("- Coin: ETH")
            print("- Side: Buy")
            print("- Size: \(orderSize)")
            print("- Price: $\(String(format: "%.2f", orderPrice))")
            print("- Client Order ID: \(clientOrderId)")
            
            print("\n🔧 ExchangeClient Methods Available:")
            print("===================================")
            print("✅ exchange.order() - Place limit/market orders")
            print("✅ exchange.marketOpen() - Market orders with slippage")
            print("✅ exchange.cancel() - Cancel by order ID")
            print("✅ exchange.cancelByCloid() - Cancel by client order ID")
            
            print("\n📋 Order Types Supported:")
            print("========================")
            print("• Limit orders: [\"limit\": [\"tif\": \"Gtc\"]]")
            print("• Market orders: [\"limit\": [\"tif\": \"Ioc\"]]")
            print("• Trigger orders: [\"trigger\": [\"triggerPx\": price]]")
            
            print("\n🎯 Usage Example:")
            print("================")
            print("""
            // Place order
            let result = try await exchange.order(
                coin: "ETH",
                isBuy: true,
                sz: 0.01,
                limitPx: 4500.0,
                orderType: ["limit": ["tif": "Gtc"]],
                cloid: "my-order-123"
            )
            
            // Cancel by client order ID
            let cancelResult = try await exchange.cancelByCloid(cloid: "my-order-123")
            """)
            
            print("\n🎉 Example completed successfully!")
            print("This demonstrates:")
            print("1. Market data retrieval")
            print("2. Order structure and parameters")
            print("3. Available trading methods")
            print("4. Order cancellation capabilities")
            print("\n💡 To test with real orders, update config.json with a valid private key")
            
        } catch {
            print("❌ Error: \(error)")
            if let nsError = error as NSError? {
                print("Error domain: \(nsError.domain)")
                print("Error code: \(nsError.code)")
                print("Error description: \(nsError.localizedDescription)")
            }
        }
    }
}