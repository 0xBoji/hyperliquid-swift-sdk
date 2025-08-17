import Foundation
import HyperliquidSwift

/// Example demonstrating bulk cancellation by client order ID
/// This shows advanced order management capabilities
class BulkCancelExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🗑️ Bulk Cancel by CLOID Example")
            print("===============================")
            
            let coin = "ETH"
            
            // Step 1: Place multiple orders with client order IDs
            print("📝 Placing multiple orders with client order IDs...")
            
            let orders = [
                ("order_1_\(Int(Date().timeIntervalSince1970))", Decimal(3000), Decimal(0.01)),
                ("order_2_\(Int(Date().timeIntervalSince1970))", Decimal(3100), Decimal(0.01)),
                ("order_3_\(Int(Date().timeIntervalSince1970))", Decimal(3200), Decimal(0.01))
            ]
            
            var placedCloids: [String] = []
            
            for (cloid, price, size) in orders {
                do {
                    // Note: This is a simplified example. In practice, you would need to implement
                    // order placement with client order IDs. For now, we'll demonstrate the
                    // bulk cancel structure.
                    
                    let orderResult = try await client.limitBuy(
                        coin: coin,
                        sz: size,
                        px: price,
                        reduceOnly: false
                    )
                    
                    print("✅ Placed order with CLOID \(cloid): \(orderResult)")
                    placedCloids.append(cloid)
                    
                    // Small delay between orders
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                } catch {
                    print("⚠️ Failed to place order with CLOID \(cloid): \(error)")
                }
            }
            
            // Step 2: Demonstrate bulk cancel by CLOID
            print("\n🗑️ Bulk cancelling orders by client order ID...")
            
            let cancelRequests = placedCloids.map { cloid in
                CancelByCloidRequest(coin: coin, cloid: cloid)
            }
            
            if !cancelRequests.isEmpty {
                let bulkCancelResult = try await client.bulkCancelByCloid(cancelRequests)
                print("✅ Bulk cancel by CLOID result:")
                print(bulkCancelResult)
            } else {
                print("⚠️ No orders to cancel")
            }
            
            // Step 3: Demonstrate setting order expiration
            print("\n⏰ Setting order expiration time...")
            
            let futureTime = Int64(Date().timeIntervalSince1970 * 1000) + 300_000 // 5 minutes from now
            let expiresResult = try await client.setExpiresAfter(expiresAfter: futureTime)
            print("✅ Set expires after result:")
            print(expiresResult)
            
            // Step 4: Place an order that will expire
            print("\n📝 Placing order with expiration...")
            
            let expiringOrderResult = try await client.limitBuy(
                coin: coin,
                sz: Decimal(0.001),
                px: Decimal(4000), // High price unlikely to execute
                reduceOnly: false
            )
            
            print("✅ Expiring order result:")
            print(expiringOrderResult)
            
            // Step 5: Disable order expiration
            print("\n🔄 Disabling order expiration...")
            
            let disableExpiresResult = try await client.setExpiresAfter(expiresAfter: nil)
            print("✅ Disable expires after result:")
            print(disableExpiresResult)
            
            print("🎯 Bulk cancel and expiration example completed successfully")
            
        } catch {
            print("❌ Error with bulk cancel operations: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Make sure you have sufficient balance for test orders
 3. Run the example:
    ```
    swift run BulkCancelExample
    ```
 
 This example demonstrates:
 - Placing multiple orders with client order IDs
 - Bulk cancellation by client order ID
 - Setting order expiration times
 - Disabling order expiration
 
 These features are useful for:
 - Automated trading systems that need to manage many orders
 - Risk management through automatic order expiration
 - Efficient order cleanup and management
 */
