import Foundation
import HyperliquidSwift

/// Example demonstrating Take Profit and Stop Loss (TPSL) orders
/// This corresponds to the Python example: basic_tpsl.py
class TPSLOrdersExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🎯 TPSL Orders Example")
            print("======================")
            
            let coin = "ETH"
            let orderSize = Decimal(0.02)
            let isBuy = true // Change this to test different scenarios
            
            // Step 1: Place an aggressive order that should execute immediately
            print("📈 Placing aggressive order to establish position...")
            
            let aggressivePrice = isBuy ? Decimal(2500) : Decimal(1500)
            let marketOrder = try await client.marketBuy(
                coin: coin,
                sz: orderSize
            )
            
            print("✅ Market order result:")
            print(marketOrder)
            
            // Wait a moment for the order to execute
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Step 2: Place a stop loss order
            print("\n🛑 Placing stop loss order...")
            
            let stopLossTrigger = isBuy ? Decimal(1600) : Decimal(2400)
            let stopLossResult = try await client.stopLossOrder(
                coin: coin,
                isBuy: !isBuy, // Opposite direction to close position
                sz: orderSize,
                triggerPx: stopLossTrigger,
                isMarket: true,
                reduceOnly: true
            )
            
            print("✅ Stop loss order result:")
            print(stopLossResult)
            
            // Step 3: Cancel the stop loss order if it was placed successfully
            if let response = stopLossResult.dictionary,
               let status = response["status"] as? String,
               status == "ok",
               let data = response["response"] as? [String: Any],
               let statuses = data["data"] as? [String: Any],
               let statusArray = statuses["statuses"] as? [[String: Any]],
               let firstStatus = statusArray.first,
               let resting = firstStatus["resting"] as? [String: Any],
               let oid = resting["oid"] as? UInt64 {
                
                print("🗑️ Cancelling stop loss order...")
                let cancelResult = try await client.cancelOrder(coin: coin, oid: oid)
                print("✅ Cancel result: \(cancelResult)")
            }
            
            // Step 4: Place a take profit order
            print("\n💰 Placing take profit order...")
            
            let takeProfitTrigger = isBuy ? Decimal(1600) : Decimal(2400)
            let takeProfitResult = try await client.takeProfitOrder(
                coin: coin,
                isBuy: !isBuy, // Opposite direction to close position
                sz: orderSize,
                triggerPx: takeProfitTrigger,
                isMarket: true,
                reduceOnly: true
            )
            
            print("✅ Take profit order result:")
            print(takeProfitResult)
            
            // Step 5: Cancel the take profit order if it was placed successfully
            if let response = takeProfitResult.dictionary,
               let status = response["status"] as? String,
               status == "ok",
               let data = response["response"] as? [String: Any],
               let statuses = data["data"] as? [String: Any],
               let statusArray = statuses["statuses"] as? [[String: Any]],
               let firstStatus = statusArray.first,
               let resting = firstStatus["resting"] as? [String: Any],
               let oid = resting["oid"] as? UInt64 {
                
                print("🗑️ Cancelling take profit order...")
                let cancelResult = try await client.cancelOrder(coin: coin, oid: oid)
                print("✅ Cancel result: \(cancelResult)")
            }
            
            print("🎯 TPSL orders example completed successfully")
            
        } catch {
            print("❌ Error with TPSL orders: \(error)")
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
    swift run TPSLOrdersExample
    ```
 
 This example demonstrates:
 - Placing market orders to establish positions
 - Setting up stop loss orders for risk management
 - Setting up take profit orders to secure profits
 - Proper order cancellation and cleanup
 
 TPSL orders are essential for automated risk management in trading strategies.
 */
