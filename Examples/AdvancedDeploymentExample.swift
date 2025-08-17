import Foundation
import HyperliquidSwift

/// Example demonstrating advanced deployment operations
/// This includes spot genesis, trading pairs, and oracle management
class AdvancedDeploymentExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🚀 Advanced Deployment Example")
            print("===============================")
            
            // Step 1: Spot token genesis deployment
            print("🌟 Deploying spot token genesis...")
            
            let genesisResult = try await client.spotDeployGenesis(
                token: 12345, // Example token ID
                maxSupply: "1000000000000000000000000", // 1M tokens with 18 decimals
                noHyperliquidity: false
            )
            
            print("✅ Spot genesis deployment result:")
            print(genesisResult)
            
            // Step 2: Register spot trading pair
            print("\n📈 Registering spot trading pair...")
            
            let spotPairResult = try await client.spotDeployRegisterSpot(
                baseToken: 12345, // Our new token
                quoteToken: 0     // USDC (typically token 0)
            )
            
            print("✅ Spot pair registration result:")
            print(spotPairResult)
            
            // Step 3: User genesis for initial distribution
            print("\n👥 Setting up user genesis distribution...")
            
            let userGenesisResult = try await client.spotDeployUserGenesis(
                token: 12345,
                userAndWei: [
                    ("0x1234567890123456789012345678901234567890", "100000000000000000000"), // 100 tokens
                    ("0x0987654321098765432109876543210987654321", "50000000000000000000")   // 50 tokens
                ],
                existingTokenAndWei: [
                    (0, "1000000000"), // 1000 USDC (6 decimals)
                    (1, "500000000")   // 500 of token 1
                ]
            )
            
            print("✅ User genesis result:")
            print(userGenesisResult)
            
            // Step 4: Set oracle for perpetual
            print("\n🔮 Setting oracle for perpetual deployment...")
            
            let oracleResult = try await client.perpDeploySetOracle(
                dex: "testdex",
                oraclePrices: [
                    "BTC": "45000000000", // $45,000 with appropriate decimals
                    "ETH": "3000000000",  // $3,000 with appropriate decimals
                    "SOL": "100000000"    // $100 with appropriate decimals
                ],
                maxGas: 2000000
            )
            
            print("✅ Oracle set result:")
            print(oracleResult)
            
            // Step 5: Display deployment summary
            print("\n📊 Deployment Summary:")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🪙 Token Genesis: Token ID 12345")
            print("   - Max Supply: 1M tokens")
            print("   - Hyperliquidity: Enabled")
            print("")
            print("📈 Trading Pair: TOKEN/USDC")
            print("   - Base Token: 12345")
            print("   - Quote Token: 0 (USDC)")
            print("")
            print("👥 Initial Distribution:")
            print("   - 2 users with token allocations")
            print("   - USDC and other token distributions")
            print("")
            print("🔮 Oracle Configuration:")
            print("   - BTC: $45,000")
            print("   - ETH: $3,000") 
            print("   - SOL: $100")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            print("🎯 Advanced deployment operations completed successfully")
            
        } catch {
            print("❌ Error with advanced deployment: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Make sure your account has deployment permissions (admin/deployer role)
 3. Run the example:
    ```
    swift run AdvancedDeploymentExample
    ```
 
 This example demonstrates:
 - Spot token genesis deployment with supply limits
 - Trading pair registration for spot markets
 - User genesis for initial token distribution
 - Oracle configuration for perpetual markets
 
 Important Notes:
 - These operations require special permissions
 - Token IDs should be unique and properly managed
 - Oracle prices should be in the correct decimal format
 - Genesis operations are typically one-time setup procedures
 
 Use Cases:
 - New token launches
 - DEX infrastructure setup
 - Market creation and configuration
 - Initial liquidity distribution
 - Oracle price feed management
 */
