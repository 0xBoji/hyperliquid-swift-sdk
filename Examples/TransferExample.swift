import Foundation
import HyperliquidSwift

/// Example demonstrating transfer operations in Hyperliquid Swift SDK
/// ⚠️ WARNING: These operations involve real money transfers!
/// Only use with testnet and small amounts for testing
@main
struct TransferExample {
    static func main() async {
        print("💸 Transfer Operations Example")
        print("==============================")
        print("⚠️ WARNING: These operations involve real money!")
        print("🧪 Only use with testnet and test amounts")
        print("")
        
        // IMPORTANT: Replace with your actual private key for testing
        // Never commit real private keys to version control!
        let testPrivateKey = "0x0000000000000000000000000000000000000000000000000000000000000001"
        
        do {
            // Initialize authenticated client for transfers
            let client = try HyperliquidClient(
                environment: .testnet, // Always use testnet for examples
                privateKey: testPrivateKey
            )
            
            print("🔐 Authenticated client initialized")
            print("📍 Wallet address: \(client.walletAddress ?? "Unknown")")
            print("")
            
            // Example 1: USD Class Transfer (Spot ↔ Perp)
            print("1️⃣ USD Class Transfer (Spot ↔ Perp)")
            print("====================================")
            do {
                print("💰 Transferring 1.0 USDC from spot to perp wallet...")
                let response = try await client.usdClassTransfer(amount: Decimal(1.0), toPerp: true)
                print("✅ Transfer successful!")
                print("📄 Response: \(response.dictionary)")
                
                // Transfer back from perp to spot
                print("\n💰 Transferring 1.0 USDC from perp to spot wallet...")
                let backResponse = try await client.usdClassTransfer(amount: Decimal(1.0), toPerp: false)
                print("✅ Reverse transfer successful!")
                print("📄 Response: \(backResponse.dictionary)")
                
            } catch {
                print("❌ USD class transfer failed: \(error)")
                print("💡 This is expected with test private key")
            }
            
            // Example 2: USD Transfer to Another Address
            print("\n2️⃣ USD Transfer to Another Address")
            print("===================================")
            do {
                let destinationAddress = "0x0000000000000000000000000000000000000000"
                print("💰 Transferring 1.0 USDC to \(destinationAddress)...")
                
                let response = try await client.usdTransfer(
                    amount: Decimal(1.0),
                    destination: destinationAddress
                )
                print("✅ USD transfer successful!")
                print("📄 Response: \(response.dictionary)")
                
            } catch {
                print("❌ USD transfer failed: \(error)")
                print("💡 This is expected with test private key")
            }
            
            // Example 3: Spot Token Transfer
            print("\n3️⃣ Spot Token Transfer")
            print("=======================")
            do {
                let destinationAddress = "0x0000000000000000000000000000000000000000"
                let tokenId = "PURR:0xc4bf3f870c0e9465323c0b6ed28096c2"
                
                print("🪙 Transferring 1.0 \(tokenId) to \(destinationAddress)...")
                
                let response = try await client.spotTransfer(
                    amount: Decimal(1.0),
                    destination: destinationAddress,
                    token: tokenId
                )
                print("✅ Spot transfer successful!")
                print("📄 Response: \(response.dictionary)")
                
            } catch {
                print("❌ Spot transfer failed: \(error)")
                print("💡 This is expected with test private key")
            }
            
            // Example 4: Sub Account Transfer
            print("\n4️⃣ Sub Account Transfer")
            print("========================")
            do {
                let subAccountAddress = "0x0000000000000000000000000000000000000000"
                
                print("👥 Depositing 1.0 USD to sub account \(subAccountAddress)...")
                
                let response = try await client.subAccountTransfer(
                    subAccountUser: subAccountAddress,
                    isDeposit: true,
                    usd: Decimal(1.0)
                )
                print("✅ Sub account deposit successful!")
                print("📄 Response: \(response.dictionary)")
                
                // Withdraw from sub account
                print("\n👥 Withdrawing 1.0 USD from sub account...")
                let withdrawResponse = try await client.subAccountTransfer(
                    subAccountUser: subAccountAddress,
                    isDeposit: false,
                    usd: Decimal(1.0)
                )
                print("✅ Sub account withdrawal successful!")
                print("📄 Response: \(withdrawResponse.dictionary)")
                
            } catch {
                print("❌ Sub account transfer failed: \(error)")
                print("💡 This is expected with test private key")
            }
            
            // Example 5: Safety Best Practices
            print("\n5️⃣ Safety Best Practices")
            print("=========================")
            print("🔒 Always validate addresses before transfers")
            print("💰 Start with small test amounts")
            print("🧪 Use testnet for development and testing")
            print("📊 Check account balances before transfers")
            print("🔄 Implement proper error handling")
            print("📝 Log all transfer operations for audit")
            
            // Example 6: Error Handling Patterns
            print("\n6️⃣ Error Handling Patterns")
            print("===========================")
            
            // Demonstrate proper error handling
            do {
                // This will fail with insufficient balance or invalid key
                let response = try await client.usdTransfer(
                    amount: Decimal(1000000.0), // Large amount
                    destination: "0x0000000000000000000000000000000000000000"
                )
                print("Unexpected success: \(response.dictionary)")
            } catch let error as HyperliquidError {
                print("🔍 Caught HyperliquidError: \(error)")
                print("💡 Handle specific error types for better UX")
            } catch {
                print("🔍 Caught general error: \(error)")
                print("💡 Always have fallback error handling")
            }
            
            print("\n🎯 Transfer Example Complete!")
            print("==============================")
            print("✅ All transfer methods demonstrated")
            print("⚠️ Remember: Use real credentials and testnet for actual testing")
            print("🚀 Ready for integration into iOS/macOS applications")
            
        } catch {
            print("❌ Failed to initialize client: \(error)")
            print("💡 Check your private key format and network connectivity")
        }
    }
}
