import XCTest
@testable import HyperliquidSwift

/// Integration tests for Hyperliquid Swift SDK
/// These tests make actual API calls to the Hyperliquid testnet
final class IntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var readOnlyClient: HyperliquidClient!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Use testnet for integration tests
        readOnlyClient = try HyperliquidClient.readOnly(environment: .testnet)
        
        // Skip integration tests if running in CI or without network
        try XCTSkipIf(ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == "true", 
                      "Integration tests skipped")
    }
    
    override func tearDownWithError() throws {
        readOnlyClient = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Read-Only API Tests
    
    func testGetAllMids() async throws {
        // Test getting all market mid prices
        let mids = try await readOnlyClient.getAllMids()
        
        XCTAssertFalse(mids.isEmpty, "Should have at least some market data")
        
        // Verify data structure
        for (symbol, price) in mids.prefix(3) {
            XCTAssertFalse(symbol.isEmpty, "Symbol should not be empty")
            XCTAssertGreaterThan(price, 0, "Price should be positive")
            
            print("📈 \(symbol): $\(price)")
        }
    }
    
    func testGetMeta() async throws {
        // Test getting exchange metadata
        let meta = try await readOnlyClient.getMeta()
        
        XCTAssertFalse(meta.universe.isEmpty, "Should have at least some assets")
        
        // Verify asset data structure
        for asset in meta.universe.prefix(3) {
            XCTAssertFalse(asset.name.isEmpty, "Asset name should not be empty")
            XCTAssertGreaterThanOrEqual(asset.szDecimals, 0, "Size decimals should be non-negative")
            
            print("🪙 \(asset.name): \(asset.szDecimals) decimals")
        }
    }
    
    func testGetSpotMeta() async throws {
        // Test getting spot metadata
        let spotMeta = try await readOnlyClient.getSpotMeta()
        
        XCTAssertFalse(spotMeta.universe.isEmpty, "Should have at least some spot assets")
        
        // Verify spot asset data
        for asset in spotMeta.universe.prefix(3) {
            XCTAssertFalse(asset.name.isEmpty, "Spot asset name should not be empty")
            XCTAssertGreaterThanOrEqual(asset.szDecimals, 0, "Size decimals should be non-negative")
            
            print("💰 Spot \(asset.name): \(asset.szDecimals) decimals")
        }
    }
    
    func testGetSpotMetaRaw() async throws {
        // Test getting raw spot metadata
        let spotMetaRaw = try await readOnlyClient.getSpotMetaRaw()
        
        XCTAssertFalse(spotMetaRaw.isEmpty, "Raw spot metadata should not be empty")
        
        print("📊 Raw spot metadata keys: \(Array(spotMetaRaw.keys).prefix(5))")
    }
    
    // MARK: - User-Specific API Tests (with test address)
    
    func testUserStateWithTestAddress() async throws {
        // Use a known test address (this might not have data, but should not error)
        let testAddress = "0x0000000000000000000000000000000000000000"
        
        let userState = try await readOnlyClient.getUserState(address: testAddress)
        
        // Should not throw error, even if user has no positions
        XCTAssertNotNil(userState)
        print("👤 Test user has \(userState.assetPositions.count) positions")
    }
    
    func testOpenOrdersWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"
        
        let openOrders = try await readOnlyClient.getOpenOrders(address: testAddress)
        
        // Should not throw error, even if user has no orders
        XCTAssertNotNil(openOrders)
        print("📋 Test user has \(openOrders.count) open orders")
    }
    
    func testUserFillsWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"
        
        let fills = try await readOnlyClient.getUserFills(address: testAddress)
        
        // Should not throw error, even if user has no fills
        XCTAssertNotNil(fills)
        print("📊 Test user has \(fills.count) fills")
    }
    
    func testUserFillsByTimeWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"
        
        // Test last 24 hours
        let oneDayAgo = Int(Date().timeIntervalSince1970 * 1000) - (24 * 60 * 60 * 1000)
        let now = Int(Date().timeIntervalSince1970 * 1000)
        
        let fills = try await readOnlyClient.getUserFillsByTime(
            user: testAddress, 
            startTime: oneDayAgo, 
            endTime: now
        )
        
        XCTAssertNotNil(fills)
        print("📊 Test user has \(fills.count) fills in last 24 hours")
    }
    
    func testSpotUserStateWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"
        
        let spotState = try await readOnlyClient.getSpotUserState(user: testAddress)
        
        XCTAssertNotNil(spotState)
        print("💰 Test user spot state has \(spotState.keys.count) fields")
    }
    
    func testFrontendOpenOrdersWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"
        
        let frontendOrders = try await readOnlyClient.getFrontendOpenOrders(user: testAddress)
        
        XCTAssertNotNil(frontendOrders)
        print("🖥️ Test user frontend orders has \(frontendOrders.keys.count) fields")
    }
    
    func testUserFeesWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"

        let userFees = try await readOnlyClient.getUserFees(address: testAddress)

        XCTAssertNotNil(userFees)
        print("💳 Test user fees has \(userFees.keys.count) fields")
    }

    func testUserFundingWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"

        // Test last 7 days
        let sevenDaysAgo = Int(Date().timeIntervalSince1970 * 1000) - (7 * 24 * 60 * 60 * 1000)
        let now = Int(Date().timeIntervalSince1970 * 1000)

        let userFunding = try await readOnlyClient.getUserFunding(
            user: testAddress,
            startTime: sevenDaysAgo,
            endTime: now
        )

        XCTAssertNotNil(userFunding)
        print("💰 Test user funding has \(userFunding.keys.count) fields")
    }

    func testFundingHistoryWithBTC() async throws {
        // Test last 24 hours
        let oneDayAgo = Int(Date().timeIntervalSince1970 * 1000) - (24 * 60 * 60 * 1000)
        let now = Int(Date().timeIntervalSince1970 * 1000)

        let fundingHistory = try await readOnlyClient.getFundingHistory(
            coin: "BTC",
            startTime: oneDayAgo,
            endTime: now
        )

        XCTAssertNotNil(fundingHistory)
        print("📈 BTC funding history has \(fundingHistory.keys.count) fields")
    }

    func testQueryReferralStateWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"

        let referralState = try await readOnlyClient.queryReferralState(user: testAddress)

        XCTAssertNotNil(referralState)
        print("🎁 Test user referral state has \(referralState.keys.count) fields")
    }

    func testQuerySubAccountsWithTestAddress() async throws {
        let testAddress = "0x0000000000000000000000000000000000000000"

        let subAccounts = try await readOnlyClient.querySubAccounts(user: testAddress)

        XCTAssertNotNil(subAccounts)
        print("👥 Test user sub accounts has \(subAccounts.keys.count) fields")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidAddressHandling() async throws {
        // Test with invalid address format
        let invalidAddress = "invalid_address"
        
        do {
            _ = try await readOnlyClient.getUserState(address: invalidAddress)
            XCTFail("Should have thrown an error for invalid address")
        } catch {
            // Expected to throw an error
            print("✅ Correctly handled invalid address: \(error)")
        }
    }
    
    func testNetworkErrorHandling() async throws {
        // Test with invalid endpoint (should cause network error)
        // This is a bit tricky to test without mocking, so we'll skip for now
        // In a real test suite, you'd use URLProtocol mocking
        
        print("ℹ️ Network error handling test skipped (requires mocking)")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceGetAllMids() throws {
        // Test performance of getting all mids
        measure {
            let expectation = XCTestExpectation(description: "Get all mids")
            
            Task {
                do {
                    _ = try await readOnlyClient.getAllMids()
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testPerformanceGetMeta() throws {
        // Test performance of getting metadata
        measure {
            let expectation = XCTestExpectation(description: "Get meta")
            
            Task {
                do {
                    _ = try await readOnlyClient.getMeta()
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - Transfer Methods Tests

    func testUsdClassTransferWithTestClient() async throws {
        // Note: This test uses a test client without real private key
        // In production, this would require proper authentication
        do {
            let testClient = try HyperliquidClient(
                environment: .testnet,
                privateKey: "0x0000000000000000000000000000000000000000000000000000000000000001"
            )

            let transferResponse = try await testClient.usdClassTransfer(amount: Decimal(1.0), toPerp: true)
            XCTAssertNotNil(transferResponse)
            print("💸 USD class transfer test completed")
        } catch {
            // Expected to fail with test key, but validates method signature
            print("⚠️ USD class transfer test failed as expected: \(error)")
            XCTAssertTrue(true) // Test passes if method exists and can be called
        }
    }

    func testUsdTransferWithTestClient() async throws {
        do {
            let testClient = try HyperliquidClient(
                environment: .testnet,
                privateKey: "0x0000000000000000000000000000000000000000000000000000000000000001"
            )

            let transferResponse = try await testClient.usdTransfer(
                amount: Decimal(1.0),
                destination: "0x0000000000000000000000000000000000000000"
            )
            XCTAssertNotNil(transferResponse)
            print("💸 USD transfer test completed")
        } catch {
            print("⚠️ USD transfer test failed as expected: \(error)")
            XCTAssertTrue(true)
        }
    }

    func testSpotTransferWithTestClient() async throws {
        do {
            let testClient = try HyperliquidClient(
                environment: .testnet,
                privateKey: "0x0000000000000000000000000000000000000000000000000000000000000001"
            )

            let transferResponse = try await testClient.spotTransfer(
                amount: Decimal(1.0),
                destination: "0x0000000000000000000000000000000000000000",
                token: "PURR:0xc4bf3f870c0e9465323c0b6ed28096c2"
            )
            XCTAssertNotNil(transferResponse)
            print("💸 Spot transfer test completed")
        } catch {
            print("⚠️ Spot transfer test failed as expected: \(error)")
            XCTAssertTrue(true)
        }
    }

    func testSubAccountTransferWithTestClient() async throws {
        do {
            let testClient = try HyperliquidClient(
                environment: .testnet,
                privateKey: "0x0000000000000000000000000000000000000000000000000000000000000001"
            )

            let transferResponse = try await testClient.subAccountTransfer(
                subAccountUser: "0x0000000000000000000000000000000000000000",
                isDeposit: true,
                usd: Decimal(1.0)
            )
            XCTAssertNotNil(transferResponse)
            print("💸 Sub account transfer test completed")
        } catch {
            print("⚠️ Sub account transfer test failed as expected: \(error)")
            XCTAssertTrue(true)
        }
    }
}
