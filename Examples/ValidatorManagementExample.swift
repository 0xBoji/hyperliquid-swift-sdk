import Foundation
import HyperliquidSwift

/// Example demonstrating validator management operations
/// This includes profile changes and signer operations
class ValidatorManagementExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🏛️ Validator Management Example")
            print("===============================")
            
            // Step 1: Change validator profile
            print("📝 Updating validator profile...")
            
            let profileResult = try await client.changeValidatorProfile(
                nodeIp: "192.168.1.100",
                name: "UpdatedValidator",
                description: "Updated validator description",
                discordUsername: "newuser#5678",
                commissionRate: "0.03" // 3% commission
            )
            
            print("✅ Validator profile update result:")
            print(profileResult)
            
            // Step 2: Demonstrate signer operations
            print("\n🔒 Signer Operations...")
            
            // Jail self (temporarily disable signing)
            print("🚫 Jailing self as signer...")
            let jailResult = try await client.cSignerJailSelf()
            print("✅ Jail result:")
            print(jailResult)
            
            // Wait a moment
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Unjail self (re-enable signing)
            print("✅ Unjailing self as signer...")
            let unjailResult = try await client.cSignerUnjailSelf()
            print("✅ Unjail result:")
            print(unjailResult)
            
            print("🎯 Validator management operations completed successfully")
            
        } catch {
            print("❌ Error with validator management: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Make sure your account is registered as a validator
 3. Run the example:
    ```
    swift run ValidatorManagementExample
    ```
 
 This example demonstrates:
 - Updating validator profile information
 - Jailing/unjailing signer operations
 - Validator network management
 
 Note: These operations require validator permissions and should only be used
 by accounts that are registered validators on the network.
 */
