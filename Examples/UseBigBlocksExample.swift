import Foundation
import HyperliquidSwift

/// Example demonstrating how to enable/disable big blocks on the EVM
/// This corresponds to the Python example: basic_evm_use_big_blocks.py
class UseBigBlocksExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🔄 Configuring big blocks settings...")
            
            // Enable big blocks for better performance
            print("📈 Enabling big blocks...")
            let enableResult = try await client.useBigBlocks(enable: true)
            print("✅ Enable big blocks result:")
            print(enableResult)
            
            // Wait a moment to demonstrate the change
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Disable big blocks
            print("📉 Disabling big blocks...")
            let disableResult = try await client.useBigBlocks(enable: false)
            print("✅ Disable big blocks result:")
            print(disableResult)
            
            print("🎯 Big blocks configuration completed successfully")
            
        } catch {
            print("❌ Error configuring big blocks: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Run the example:
    ```
    swift run UseBigBlocksExample
    ```
 
 Big blocks can improve performance for high-frequency trading operations
 by allowing larger transaction batches to be processed together.
 */
