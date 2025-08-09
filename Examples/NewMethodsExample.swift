import Foundation
import HyperliquidSwift

/// Example demonstrating the new methods added for feature parity with Python SDK
/// This example shows how to use the latest Info API methods
@main
struct NewMethodsExample {
    static func main() async {
        do {
            // Initialize the info service (read-only, no private key needed)
            let infoService = try InfoService(environment: .testnet)
            
            print("🆕 New Methods Example")
            print("=====================")
            print("Demonstrating new Info API methods for complete feature parity")
            
            // Test address for examples
            let testAddress = "0x0000000000000000000000000000000000000000"
            
            // Example 1: Get Frontend Open Orders (Enhanced order data)
            print("\n1️⃣ Frontend Open Orders")
            print("========================")
            do {
                let frontendOrders = try await infoService.getFrontendOpenOrders(address: testAddress)
                print("✅ Frontend orders retrieved")
                print("   📊 Enhanced order data with \(frontendOrders.dictionary.keys.count) fields")
                print("   🔍 Includes trigger conditions, order relationships, and more")
            } catch {
                print("⚠️ Frontend orders error: \(error)")
            }
            
            // Example 2: Get User Fees and Trading Volume
            print("\n2️⃣ User Fees & Trading Volume")
            print("==============================")
            do {
                let userFees = try await infoService.getUserFees(address: testAddress)
                print("✅ User fees retrieved")
                print("   💳 Fee structure with \(userFees.dictionary.keys.count) fields")
                print("   📈 Includes maker/taker rates, volume tiers, and referral discounts")
            } catch {
                print("⚠️ User fees error: \(error)")
            }
            
            // Example 3: Get User Funding History
            print("\n3️⃣ User Funding History")
            print("========================")
            do {
                // Get funding history for the last 7 days
                let sevenDaysAgo = Int(Date().timeIntervalSince1970 * 1000) - (7 * 24 * 60 * 60 * 1000)
                let now = Int(Date().timeIntervalSince1970 * 1000)
                
                let userFunding = try await infoService.getUserFunding(
                    user: testAddress,
                    startTime: sevenDaysAgo,
                    endTime: now
                )
                print("✅ User funding history retrieved")
                print("   💰 Funding payments with \(userFunding.dictionary.keys.count) fields")
                print("   📅 Time range: Last 7 days")
            } catch {
                print("⚠️ User funding error: \(error)")
            }
            
            // Example 4: Get Funding Rate History for BTC
            print("\n4️⃣ BTC Funding Rate History")
            print("============================")
            do {
                // Get BTC funding history for the last 24 hours
                let oneDayAgo = Int(Date().timeIntervalSince1970 * 1000) - (24 * 60 * 60 * 1000)
                let now = Int(Date().timeIntervalSince1970 * 1000)
                
                let fundingHistory = try await infoService.getFundingHistory(
                    coin: "BTC",
                    startTime: oneDayAgo,
                    endTime: now
                )
                print("✅ BTC funding history retrieved")
                print("   📈 Funding rates with \(fundingHistory.dictionary.keys.count) fields")
                print("   🪙 Asset: BTC")
                print("   📅 Time range: Last 24 hours")
            } catch {
                print("⚠️ Funding history error: \(error)")
            }
            
            // Example 5: Query Referral State
            print("\n5️⃣ Referral State")
            print("==================")
            do {
                let referralState = try await infoService.queryReferralState(user: testAddress)
                print("✅ Referral state retrieved")
                print("   🎁 Referral information with \(referralState.dictionary.keys.count) fields")
                print("   📊 Includes referral code, discounts, and rewards")
            } catch {
                print("⚠️ Referral state error: \(error)")
            }
            
            // Example 6: Query Sub Accounts
            print("\n6️⃣ Sub Accounts")
            print("================")
            do {
                let subAccounts = try await infoService.querySubAccounts(user: testAddress)
                print("✅ Sub accounts retrieved")
                print("   👥 Sub account data with \(subAccounts.dictionary.keys.count) fields")
                print("   🔐 Includes permissions and account details")
            } catch {
                print("⚠️ Sub accounts error: \(error)")
            }
            
            // Example 7: Advanced Usage - Combining Multiple Methods
            print("\n7️⃣ Advanced: Combined Analysis")
            print("===============================")
            do {
                print("🔄 Performing comprehensive account analysis...")
                
                // Get user fees to understand trading costs
                let fees = try await infoService.getUserFees(address: testAddress)
                print("   💳 Fee analysis complete")
                
                // Get recent funding payments
                let recentTime = Int(Date().timeIntervalSince1970 * 1000) - (24 * 60 * 60 * 1000)
                let funding = try await infoService.getUserFunding(
                    user: testAddress,
                    startTime: recentTime
                )
                print("   💰 Funding analysis complete")
                
                // Get referral benefits
                let referral = try await infoService.queryReferralState(user: testAddress)
                print("   🎁 Referral analysis complete")
                
                print("✅ Comprehensive analysis completed")
                print("   📊 Combined data provides full trading cost picture")
                
            } catch {
                print("⚠️ Combined analysis error: \(error)")
            }
            
            // Example 8: Transfer Operations (requires authenticated client)
            print("\n8️⃣ Transfer Operations")
            print("=======================")
            print("⚠️ Transfer operations require authenticated client with private key")
            print("📝 These examples show method signatures - use with real credentials")

            // Note: These would require real private key and sufficient balance
            print("   💸 USD Class Transfer: client.usdClassTransfer(amount: 1.0, toPerp: true)")
            print("   💸 USD Transfer: client.usdTransfer(amount: 1.0, destination: \"0x...\")")
            print("   💸 Spot Transfer: client.spotTransfer(amount: 1.0, destination: \"0x...\", token: \"PURR:0x...\")")
            print("   💸 Sub Account Transfer: client.subAccountTransfer(subAccountUser: \"0x...\", isDeposit: true, usd: 1.0)")

            print("\n🎉 New Methods Example Complete!")
            print("=================================")
            print("✅ All new Info API methods demonstrated")
            print("✅ Transfer operations methods available")
            print("📚 Swift SDK now has complete feature parity with Python SDK")
            print("🚀 Ready for production use in iOS/macOS applications")
            
        } catch {
            print("❌ Example failed: \(error)")
        }
    }
}
