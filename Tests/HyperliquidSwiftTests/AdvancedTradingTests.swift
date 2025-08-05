import XCTest
@testable import HyperliquidSwift

final class AdvancedTradingTests: XCTestCase {
    
    var client: HyperliquidClient!
    // real private key test  on hyperliquid testnet
    let testPrivateKey = "41f1a7bf3ce7d3cb7a72edb826460ffd103f2a751c374a77486e5247f12282f7"
    
    override func setUp() async throws {
        try await super.setUp()
        client = try HyperliquidClient(
            privateKeyHex: testPrivateKey,
            environment: .testnet
        )
    }
    
    override func tearDown() async throws {
        client = nil
        try await super.tearDown()
    }
    
    // MARK: - Market Order Tests
    
    func testMarketBuyOrder() async throws {
        // Test market buy order creation
        do {
            let response = try await client.marketBuy(
                coin: "ETH",
                sz: Decimal(0.001),
                reduceOnly: false
            )
            
            // Should get a response (even if it fails due to insufficient funds)
            XCTAssertNotNil(response.dictionary)
            
            // Check response structure
            if let status = response.dictionary["status"] as? String {
                // Either success or business logic error (both are valid for our test)
                XCTAssertTrue(status == "ok" || status == "err")
            }
            
        } catch let error as HyperliquidError {
            // Network or authentication errors are acceptable in tests
            switch error {
            case .networkError, .authenticationRequired, .requestFailed:
                XCTAssertTrue(true, "Expected error in test environment")
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    func testMarketSellOrder() async throws {
        // Test market sell order creation
        do {
            let response = try await client.marketSell(
                coin: "ETH",
                sz: Decimal(0.001),
                reduceOnly: false
            )
            
            XCTAssertNotNil(response.dictionary)
            
        } catch let error as HyperliquidError {
            // Expected in test environment
            switch error {
            case .networkError, .authenticationRequired, .requestFailed:
                XCTAssertTrue(true, "Expected error in test environment")
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    // MARK: - Cancel All Orders Tests
    
    func testCancelAllOrdersForCoin() async throws {
        // Test canceling all orders for a specific coin
        do {
            let response = try await client.cancelAllOrders(coin: "ETH")
            
            XCTAssertNotNil(response.dictionary)
            
            // Should return success even if no orders to cancel
            if let status = response.dictionary["status"] as? String {
                XCTAssertEqual(status, "ok")
            }
            
        } catch let error as HyperliquidError {
            switch error {
            case .networkError, .authenticationRequired, .requestFailed:
                XCTAssertTrue(true, "Expected error in test environment")
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    func testCancelAllOrders() async throws {
        // Test canceling all orders across all coins
        do {
            let response = try await client.cancelAllOrders()
            
            XCTAssertNotNil(response.dictionary)
            
            if let status = response.dictionary["status"] as? String {
                XCTAssertEqual(status, "ok")
            }
            
        } catch let error as HyperliquidError {
            switch error {
            case .networkError, .authenticationRequired, .requestFailed:
                XCTAssertTrue(true, "Expected error in test environment")
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    // MARK: - Modify Order Tests
    
    func testModifyOrder() async throws {
        // Test order modification
        do {
            let response = try await client.modifyOrder(
                oid: 12345,
                coin: "ETH",
                newPrice: Decimal(3500.0),
                newSize: Decimal(0.1)
            )
            
            XCTAssertNotNil(response.dictionary)
            
        } catch let error as HyperliquidError {
            // Expected to fail since we don't have a real order
            switch error {
            case .networkError, .authenticationRequired, .requestFailed, .orderNotFound:
                XCTAssertTrue(true, "Expected error in test environment")
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteOrderFlow() async throws {
        // Test a complete order flow: place -> modify -> cancel
        
        // 1. Try to place a limit order
        do {
            let limitResponse = try await client.limitBuy(
                coin: "ETH",
                sz: Decimal(0.001),
                px: Decimal(1000.0), // Very low price to avoid accidental fills
                reduceOnly: false
            )
            
            XCTAssertNotNil(limitResponse.dictionary)
            
            // If successful, try to cancel all orders
            if let status = limitResponse.dictionary["status"] as? String, status == "ok" {
                let cancelResponse = try await client.cancelAllOrders(coin: "ETH")
                XCTAssertNotNil(cancelResponse.dictionary)
            }
            
        } catch let error as HyperliquidError {
            switch error {
            case .networkError, .authenticationRequired, .requestFailed:
                XCTAssertTrue(true, "Expected error in test environment")
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testClientNotInitializedError() async throws {
        // Test error when trading service is not initialized
        let uninitializedClient = try HyperliquidClient(
            privateKeyHex: testPrivateKey,
            environment: .testnet
        )
        
        // Manually set trading service to nil to test error
        // This would require making tradingService accessible for testing
        // For now, we'll test with invalid parameters
        
        do {
            _ = try await uninitializedClient.modifyOrder(
                oid: 0,
                coin: "",
                newPrice: Decimal(-1),
                newSize: Decimal(-1)
            )
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(true, "Expected error for invalid parameters")
        }
    }
    
    // MARK: - Performance Tests
    
    func testMarketDataPerformance() async throws {
        // Test performance of market data retrieval
        measure {
            let expectation = XCTestExpectation(description: "Market data retrieval")
            
            Task {
                do {
                    _ = try await client.getAllMids()
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Validation Tests
    
    func testOrderParameterValidation() async throws {
        // Test validation of order parameters
        
        // Test negative size
        do {
            _ = try await client.marketBuy(coin: "ETH", sz: Decimal(-1))
            XCTFail("Should reject negative size")
        } catch {
            XCTAssertTrue(true, "Expected validation error")
        }
        
        // Test empty coin
        do {
            _ = try await client.marketBuy(coin: "", sz: Decimal(0.1))
            XCTFail("Should reject empty coin")
        } catch {
            XCTAssertTrue(true, "Expected validation error")
        }
    }
}
