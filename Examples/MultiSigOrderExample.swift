import Foundation
import HyperliquidSwift

/// Example demonstrating how to execute multi-signature orders
/// This corresponds to the Python example: multi_sig_order.py
class MultiSigOrderExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🔄 Executing multi-signature order...")
            
            // The outer signer is required to be an authorized user or an agent of the authorized user
            // of the multi-sig user.
            
            // Address of the multi-sig user that the action will be executed for
            // Executing the action requires at least the specified threshold of signatures
            // required for that multi-sig user
            let multiSigUser = "0x0000000000000000000000000000000000000005"
            
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            
            // Define the multi-sig inner action (placing a limit order)
            let innerAction: [String: any Sendable] = [
                "type": "order",
                "orders": [[
                    "a": 4, // Asset ID for the coin
                    "b": true, // Buy order
                    "p": "1100", // Price
                    "s": "0.2", // Size
                    "r": false, // Not reduce-only
                    "t": ["limit": ["tif": "Gtc"]] // Good till cancelled limit order
                ]],
                "grouping": "na"
            ]
            
            // In a real implementation, you would collect signatures from multiple wallets
            // For this example, we'll show the structure with placeholder signatures
            let signatures = [
                "0x1234567890abcdef...", // Signature from authorized user 1
                "0xfedcba0987654321..."  // Signature from authorized user 2
            ]
            
            // Execute the multi-sig action with all collected signatures
            // This will only succeed if enough valid signatures are provided
            let multiSigResult = try await client.multiSig(
                multiSigUser: multiSigUser,
                innerAction: innerAction,
                signatures: signatures,
                nonce: timestamp
            )
            
            print("✅ Multi-sig order result:")
            print(multiSigResult)
            
            print("🎯 Multi-signature order execution completed")
            
        } catch {
            print("❌ Error executing multi-sig order: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Make sure you have access to a multi-signature user account
 3. Collect valid signatures from the required number of authorized users
 4. Run the example:
    ```
    swift run MultiSigOrderExample
    ```
 
 Note: This example uses placeholder signatures. In a real implementation,
 you would need to:
 1. Generate the proper EIP-712 signatures from each authorized wallet
 2. Ensure you have the minimum required number of signatures (threshold)
 3. Use the correct nonce and timestamp values
 */
