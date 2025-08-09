import Foundation
import HyperliquidSwift

/// Basic usage examples for Hyperliquid Swift SDK

@main
struct BasicUsageExample {
    static func main() async {
        await runExamples()
    }

    static func runExamples() async {
        print("🚀 Hyperliquid Swift SDK - Basic Usage Examples")
        print("==================================================")

        // Example 1: Read-only client (no authentication)
        await readOnlyExamples()

        // Example 2: Authenticated client examples
        await authenticatedExamples()

        print("\n✅ All examples completed!")
    }
    
    // MARK: - Read-Only Examples

    static func readOnlyExamples() async {
        print("\n📖 READ-ONLY EXAMPLES (No authentication required)")
        print("----------------------------------------")

        do {
            // Create read-only client for testnet
            let client = try HyperliquidClient.readOnly(environment: .testnet)

            // Print market summary using utility function
            try await ExampleUtils.printMarketSummary(client)

            // Example 1: Get all market mid prices
            print("\n1️⃣ Getting all market mid prices...")
            let mids = try await client.getAllMids()
            print("✅ Found \(mids.count) markets")

            // Verify we have expected markets
            let expectedMarkets = ["BTC", "ETH", "SOL"]
            for market in expectedMarkets {
                if let price = mids[market] {
                    print("   📈 \(market): $\(price)")
                } else {
                    print("   ⚠️  \(market): Not found")
                }
            }

            // Example 2: Get exchange metadata
            print("\n2️⃣ Getting exchange metadata...")
            let meta = try await client.getMeta()
            print("✅ Exchange has \(meta.universe.count) assets")

            // Verify metadata structure
            guard !meta.universe.isEmpty else {
                throw ExampleError.invalidConfiguration("No assets found in metadata")
            }

            // Show first few assets with validation
            for asset in meta.universe.prefix(3) {
                print("   🪙 \(asset.name): \(asset.szDecimals) decimals, max leverage: \(asset.maxLeverage)x")
            }

            // Example 3: Get spot market metadata
            print("\n3️⃣ Getting spot market metadata...")
            let spotMeta = try await client.getSpotMeta()
            print("✅ Spot exchange has \(spotMeta.universe.count) assets")

            // Show spot assets
            for asset in spotMeta.universe.prefix(3) {
                print("   💰 \(asset.name): \(asset.szDecimals) decimals")
            }

        } catch {
            print("❌ Read-only example failed: \(error)")
            if let exampleError = error as? ExampleError {
                print("   Details: \(exampleError.localizedDescription)")
            }
        }
    }
    
    // MARK: - Authenticated Examples

    static func authenticatedExamples() async {
        print("\n🔐 AUTHENTICATED EXAMPLES")
        print("----------------------------------------")

        do {
            // Setup using config file 
            let (address, client) = try await ExampleUtils.setup(environment: .testnet)

            // Print account summary
            try await ExampleUtils.printAccountSummary(client, address: address)
            
            // Example 1: Get user state (with proper validation)
            print("\n1️⃣ Getting user state...")
            let userState = try await client.getUserState(address: address)
            print("✅ User has \(userState.assetPositions.count) asset positions")
            print("   💰 Account value: $\(userState.crossMarginSummary.accountValue)")
            print("   📊 Margin used: $\(userState.crossMarginSummary.totalMarginUsed)")
            print("   ⚖️  Maintenance margin: $\(userState.crossMaintenanceMarginUsed)")

            // Validate user state structure 
            assert(userState.crossMarginSummary.accountValue > 0, "Account value should be positive")
            assert(userState.crossMaintenanceMarginUsed >= 0, "Maintenance margin should be non-negative")

            // Example 2: Get open orders (with validation)
            print("\n2️⃣ Getting open orders...")
            let openOrders = try await client.getOpenOrders(address: address)
            print("✅ User has \(openOrders.count) open orders")

            // Validate order structure if orders exist
            for order in openOrders.prefix(3) {
                print("   📋 \(order.coin): \(order.side == .buy ? "Buy" : "Sell") \(order.sz) @ $\(order.limitPx)")

                // Validate order fields
                assert(!order.coin.isEmpty, "Order coin should not be empty")
                assert(order.oid > 0, "Order ID should be positive")
                assert([Side.buy, Side.sell].contains(order.side), "Order side should be buy or sell")
            }

            // Example 3: Get user fills (with validation)
            print("\n3️⃣ Getting user fills...")
            let fills = try await client.getUserFills(address: address)
            print("✅ User has \(fills.count) recent fills")

            // Validate fill structure
            for fill in fills.prefix(3) {
                print("   📊 \(fill.coin): \(fill.sz) @ $\(fill.px) (fee: $\(fill.fee))")

                // Validate fill fields
                assert(!fill.coin.isEmpty, "Fill coin should not be empty")
                assert(fill.px > 0, "Fill price should be positive")
                assert(fill.sz > 0, "Fill size should be positive")
                assert(fill.oid > 0, "Fill order ID should be positive")
            }

            // Example 4: Get user fills by time range (with proper time validation)
            print("\n4️⃣ Getting user fills by time range...")
            let oneDayAgo = Int(Date().timeIntervalSince1970 * 1000) - (24 * 60 * 60 * 1000)
            let now = Int(Date().timeIntervalSince1970 * 1000)
            let recentFills = try await client.getUserFillsByTime(user: address, startTime: oneDayAgo, endTime: now)
            print("✅ Found \(recentFills.count) fills in last 24 hours")

            // Validate time range fills
            for fill in recentFills.prefix(3) {
                let fillTimeMs = Int(fill.time) // fill.time is already Int64 timestamp in ms
                assert(fillTimeMs >= oneDayAgo, "Fill time should be within range")
                assert(fillTimeMs <= now, "Fill time should not be in future")
            }
            
            // Example 5: Get user fees and trading volume
            print("\n5️⃣ Getting user fees...")
            let userFees = try await client.getUserFees(address: testAddress)
            print("✅ User fees retrieved")
            print("   💳 Fee structure: \(userFees.keys.count) fields")

            // Example 6: Get user funding history
            print("\n6️⃣ Getting user funding history...")
            let userFunding = try await client.getUserFunding(
                user: testAddress,
                startTime: oneDayAgo,
                endTime: now
            )
            print("✅ User funding history retrieved")
            print("   💰 Funding records: \(userFunding.keys.count) fields")

            // Example 7: Get funding history for BTC
            print("\n7️⃣ Getting BTC funding history...")
            let fundingHistory = try await client.getFundingHistory(
                coin: "BTC",
                startTime: oneDayAgo,
                endTime: now
            )
            print("✅ BTC funding history retrieved")
            print("   📈 Funding data: \(fundingHistory.keys.count) fields")

            // Example 8: Get frontend open orders (enhanced)
            print("\n8️⃣ Getting frontend open orders...")
            let frontendOrders = try await client.getFrontendOpenOrders(address: testAddress)
            print("✅ Frontend open orders retrieved")
            print("   🖥️ Enhanced order data: \(frontendOrders.keys.count) fields")

            // Example 9: Get referral state
            print("\n9️⃣ Getting referral state...")
            let referralState = try await client.queryReferralState(user: testAddress)
            print("✅ Referral state retrieved")
            print("   🎁 Referral info: \(referralState.keys.count) fields")

            // Example 10: Get sub-accounts
            print("\n🔟 Getting sub-accounts...")
            let subAccounts = try await client.querySubAccounts(user: testAddress)
            print("✅ Sub-accounts retrieved")
            print("   👥 Sub-account data: \(subAccounts.keys.count) fields")

            // Example 7: Query order by ID (with proper error handling)
            print("\n7️⃣ Querying order status...")
            let testOrderId: OrderID = 12345
            let orderStatus = try await client.queryOrderByOid(oid: testOrderId)
            if let status = orderStatus {
                print("✅ Order found: \(status)")
            } else {
                print("ℹ️  No order found with ID \(testOrderId) (expected for test data)")
            }

            // Example 8: Get account summary (comprehensive)
            print("\n8️⃣ Getting account summary...")
            let summary = try await client.getAccountSummary()
            print("✅ Account Summary:")
            print("   👤 Address: \(summary.walletAddress)")
            print("   📊 Positions: \(summary.openPositionsCount)")
            print("   📋 Orders: \(summary.openOrdersCount)")
            print("   💰 Account Value: $\(summary.userState.crossMarginSummary.accountValue)")

            // Validate account summary
            assert(summary.walletAddress == address, "Summary address should match requested address")
            assert(summary.openPositionsCount >= 0, "Position count should be non-negative")
            assert(summary.openOrdersCount >= 0, "Order count should be non-negative")
            
        } catch {
            print("❌ Authenticated example failed: \(error)")

            // Show specific error types with helpful messages
            if let exampleError = error as? ExampleError {
                print("   📋 Setup Error: \(exampleError.localizedDescription)")
            } else if let hlError = error as? HyperliquidError {
                switch hlError {
                case .authenticationRequired(let message):
                    print("   🔐 Authentication issue: \(message)")
                case .invalidPrivateKey(let message):
                    print("   🔑 Private key issue: \(message)")
                case .networkError(let message):
                    print("   🌐 Network issue: \(message)")
                case .requestFailed(let statusCode, let message):
                    print("   📡 Request failed (\(statusCode)): \(message)")
                default:
                    print("   ⚠️  Other Hyperliquid error: \(hlError)")
                }
            } else {
                print("   ❓ Unexpected error: \(error)")
            }
        }
    }
}

// MARK: - Helper Extensions

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}


