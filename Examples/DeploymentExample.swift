import Foundation
import HyperliquidSwift

/// Example demonstrating token and asset deployment operations
/// This includes spot token and perpetual asset registration
class DeploymentExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🚀 Deployment Operations Example")
            print("=================================")
            
            // Step 1: Register a new spot token
            print("🪙 Registering new spot token...")
            
            let spotTokenResult = try await client.spotDeployRegisterToken(
                tokenName: "TESTTOKEN",
                szDecimals: 6,
                weiDecimals: 18,
                maxGas: 1000000,
                fullName: "Test Token for Demo"
            )
            
            print("✅ Spot token registration result:")
            print(spotTokenResult)
            
            // Step 2: Register a new perpetual asset
            print("\n📈 Registering new perpetual asset...")
            
            let perpAssetResult = try await client.perpDeployRegisterAsset(
                dex: "testdex",
                name: "TESTPERP",
                szDecimals: 4,
                maxLeverage: 20,
                onlyIsolated: false
            )
            
            print("✅ Perpetual asset registration result:")
            print(perpAssetResult)
            
            // Step 3: Display deployment summary
            print("\n📊 Deployment Summary:")
            print("- Spot Token: TESTTOKEN (6 decimals)")
            print("- Perpetual Asset: TESTPERP (20x leverage)")
            print("- Both deployments submitted to testnet")
            
            print("🎯 Deployment operations completed successfully")
            
        } catch {
            print("❌ Error with deployment operations: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Make sure your account has deployment permissions
 3. Run the example:
    ```
    swift run DeploymentExample
    ```
 
 This example demonstrates:
 - Spot token registration and deployment
 - Perpetual asset registration with leverage settings
 - Deployment parameter configuration
 
 Note: These operations require special permissions and are typically used by:
 - DEX administrators
 - Token project teams
 - Infrastructure providers
 
 Deployment operations may have significant gas costs and should be tested
 thoroughly on testnet before mainnet deployment.
 */
