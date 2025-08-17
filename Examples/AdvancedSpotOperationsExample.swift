import Foundation
import HyperliquidSwift

/// Example demonstrating advanced spot token operations
/// This includes freeze operations, hyperliquidity, and fee management
class AdvancedSpotOperationsExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🔧 Advanced Spot Operations Example")
            print("====================================")
            
            let tokenId = 12345 // Example token ID
            let spotId = 67890  // Example spot ID
            let userAddress = "0x1234567890123456789012345678901234567890"
            
            // Step 1: Enable freeze privilege for token
            print("🔒 Enabling freeze privilege for token...")
            
            let enableFreezeResult = try await client.spotDeployEnableFreezePrivilege(token: tokenId)
            print("✅ Enable freeze privilege result:")
            print(enableFreezeResult)
            
            // Step 2: Freeze a user
            print("\n❄️ Freezing user for token...")
            
            let freezeUserResult = try await client.spotDeployFreezeUser(
                token: tokenId,
                user: userAddress,
                freeze: true
            )
            print("✅ Freeze user result:")
            print(freezeUserResult)
            
            // Step 3: Unfreeze the user
            print("\n🔥 Unfreezing user for token...")
            
            let unfreezeUserResult = try await client.spotDeployFreezeUser(
                token: tokenId,
                user: userAddress,
                freeze: false
            )
            print("✅ Unfreeze user result:")
            print(unfreezeUserResult)
            
            // Step 4: Register hyperliquidity
            print("\n💧 Registering hyperliquidity for spot...")
            
            let hyperliquidityResult = try await client.spotDeployRegisterHyperliquidity(
                spot: spotId,
                startPx: 1.0,        // Starting price $1.00
                orderSz: 1000.0,     // Order size 1000 tokens
                nOrders: 10,         // 10 orders on each side
                nSeededLevels: 5     // 5 seeded levels
            )
            print("✅ Register hyperliquidity result:")
            print(hyperliquidityResult)
            
            // Step 5: Set deployer trading fee share
            print("\n💰 Setting deployer trading fee share...")
            
            let feeShareResult = try await client.spotDeploySetDeployerTradingFeeShare(
                token: tokenId,
                share: "0.1" // 10% fee share
            )
            print("✅ Set deployer trading fee share result:")
            print(feeShareResult)
            
            // Step 6: Revoke freeze privilege
            print("\n🔓 Revoking freeze privilege for token...")
            
            let revokeFreezeResult = try await client.spotDeployRevokeFreezePrivilege(token: tokenId)
            print("✅ Revoke freeze privilege result:")
            print(revokeFreezeResult)
            
            // Step 7: Display operations summary
            print("\n📊 Advanced Spot Operations Summary:")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔒 Freeze Operations:")
            print("   - Enabled freeze privilege for token \(tokenId)")
            print("   - Froze and unfroze user \(userAddress)")
            print("   - Revoked freeze privilege")
            print("")
            print("💧 Hyperliquidity Setup:")
            print("   - Spot ID: \(spotId)")
            print("   - Starting Price: $1.00")
            print("   - Order Size: 1000 tokens")
            print("   - Orders: 10 on each side")
            print("   - Seeded Levels: 5")
            print("")
            print("💰 Fee Configuration:")
            print("   - Deployer Fee Share: 10%")
            print("   - Applied to token \(tokenId)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            print("🎯 Advanced spot operations completed successfully")
            
        } catch {
            print("❌ Error with advanced spot operations: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Make sure your account has spot deployment permissions
 3. Run the example:
    ```
    swift run AdvancedSpotOperationsExample
    ```
 
 This example demonstrates:
 - Freeze privilege management for spot tokens
 - User freeze/unfreeze operations for compliance
 - Hyperliquidity registration for automated market making
 - Deployer trading fee share configuration
 - Complete spot token lifecycle management
 
 Important Notes:
 - Freeze operations require special permissions
 - Hyperliquidity setup affects market dynamics
 - Fee share configuration impacts revenue distribution
 - These operations are typically used by token deployers
 
 Use Cases:
 - Regulatory compliance (freeze/unfreeze users)
 - Automated market making setup
 - Revenue sharing configuration
 - Token lifecycle management
 - Liquidity provision optimization
 */
