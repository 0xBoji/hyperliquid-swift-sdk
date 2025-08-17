import Foundation
import HyperliquidSwift

/// Example demonstrating how to approve builder fees and place orders with builders
/// This corresponds to the Python example: basic_builder_fee.py
class BuilderFeeExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            // Important: Only the main wallet has permission to approve a builder fee
            // Agents do not have permission to perform this operation
            print("🔄 Approving builder fee...")
            
            // Builder address and maximum fee rate
            let builderAddress = "0x8c967E73E7B15087c42A10D344cFf4c96D877f1D"
            let maxFeeRate = "0.001%" // 0.001% maximum fee
            
            // Approve setting a builder fee
            let approveResult = try await client.approveBuilderFee(
                builder: builderAddress,
                maxFeeRate: maxFeeRate
            )
            
            print("✅ Builder fee approval result:")
            print(approveResult)
            
            // Now place a market order with the builder
            // This will cause an additional fee to be added to the order which is sent to the builder
            print("📈 Placing market order with builder...")
            
            let orderResult = try await client.marketBuy(
                coin: "ETH",
                sz: Decimal(0.05),
                slippage: Decimal(0.01) // 1% slippage tolerance
            )
            
            print("✅ Market order with builder result:")
            print(orderResult)
            
            print("🎯 Builder fee configuration and order placement completed")
            
        } catch {
            print("❌ Error with builder fee operations: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Make sure your account has sufficient permissions (main wallet, not agent)
 3. Ensure you have sufficient balance for the test order
 4. Run the example:
    ```
    swift run BuilderFeeExample
    ```
 
 Builder fees allow you to route orders through specific builders who may provide
 better execution or additional services in exchange for a small fee.
 */
