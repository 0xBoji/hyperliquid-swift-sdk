import XCTest
@testable import HyperliquidSwift

final class HyperliquidSwiftTests: XCTestCase {

    // MARK: - Test Properties

    var readOnlyClient: HyperliquidClient!
    let testPrivateKey = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    let testAddress = "0x1234567890123456789012345678901234567890"

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        readOnlyClient = try HyperliquidClient.readOnly(environment: .testnet)
    }

    override func tearDownWithError() throws {
        readOnlyClient = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Client Creation Tests
    
    func testReadOnlyClientCreation() throws {
        // Test read-only client creation
        let client = try HyperliquidClient.readOnly()
        XCTAssertNotNil(client)
    }
    
    func testAuthenticatedClientCreation() throws {
        // Test authenticated client creation
        let client = try HyperliquidClient.trading(privateKeyHex: testPrivateKey, environment: .testnet)
        XCTAssertNotNil(client)
    }
    
    func testInvalidPrivateKeyThrows() {
        // Test invalid private key throws error
        XCTAssertThrowsError(try HyperliquidClient.trading(privateKeyHex: "invalid", environment: .testnet)) { error in
            XCTAssertTrue(error is HyperliquidError)
            if case .invalidPrivateKey = error as? HyperliquidError {
                // Expected error type
            } else {
                XCTFail("Expected invalidPrivateKey error")
            }
        }
    }
    
    // MARK: - Constants Tests
    
    func testConstants() {
        // Test SDK constants
        XCTAssertEqual(Constants.sdkName, "HyperliquidSwift")
        XCTAssertEqual(Constants.sdkVersion, "1.0.0")
        XCTAssertEqual(Constants.userAgent, "HyperliquidSwift/1.0.0")
        
        // Test API URLs
        XCTAssertEqual(Constants.API.mainnetURL, "https://api.hyperliquid.xyz")
        XCTAssertEqual(Constants.API.testnetURL, "https://api.hyperliquid-testnet.xyz")
        
        // Test crypto constants
        XCTAssertEqual(Constants.Crypto.privateKeyLength, 32)
        XCTAssertEqual(Constants.Crypto.privateKeyHexLength, 64)
        XCTAssertEqual(Constants.Crypto.addressLength, 20)
    }
    
    // MARK: - Environment Tests
    
    func testEnvironmentConfiguration() {
        let mainnet = HyperliquidEnvironment.mainnet
        let testnet = HyperliquidEnvironment.testnet
        
        // Test mainnet configuration
        XCTAssertEqual(mainnet.apiURL, Constants.API.mainnetURL)
        XCTAssertEqual(mainnet.webSocketURL, Constants.API.mainnetWS)
        XCTAssertEqual(mainnet.chainId, Constants.ChainID.mainnet)
        
        // Test testnet configuration
        XCTAssertEqual(testnet.apiURL, Constants.API.testnetURL)
        XCTAssertEqual(testnet.webSocketURL, Constants.API.testnetWS)
        XCTAssertEqual(testnet.chainId, Constants.ChainID.testnet)
    }
    
    // MARK: - Validation Tests
    
    func testPrivateKeyValidation() {
        // Test valid private key
        XCTAssertNoThrow(try Validation.validatePrivateKey(testPrivateKey))
        
        // Test valid private key without 0x prefix
        let keyWithoutPrefix = String(testPrivateKey.dropFirst(2))
        XCTAssertNoThrow(try Validation.validatePrivateKey(keyWithoutPrefix))
        
        // Test invalid private key (too short)
        XCTAssertThrowsError(try Validation.validatePrivateKey("0x123"))
        
        // Test invalid private key (invalid characters)
        XCTAssertThrowsError(try Validation.validatePrivateKey("0x" + String(repeating: "g", count: 64)))
        
        // Test all zeros private key
        XCTAssertThrowsError(try Validation.validatePrivateKey("0x" + String(repeating: "0", count: 64)))
    }
    
    func testAddressValidation() {
        // Test valid address
        XCTAssertNoThrow(try Validation.validateAddress(testAddress))
        
        // Test invalid address (no 0x prefix)
        XCTAssertThrowsError(try Validation.validateAddress("1234567890123456789012345678901234567890"))
        
        // Test invalid address (wrong length)
        XCTAssertThrowsError(try Validation.validateAddress("0x123"))
        
        // Test invalid address (invalid characters)
        XCTAssertThrowsError(try Validation.validateAddress("0x" + String(repeating: "g", count: 40)))
    }
    
    func testOrderSizeValidation() {
        // Test valid order size
        XCTAssertNoThrow(try Validation.validateOrderSize(Decimal(100)))
        
        // Test invalid order size (zero)
        XCTAssertThrowsError(try Validation.validateOrderSize(Decimal(0)))
        
        // Test invalid order size (negative)
        XCTAssertThrowsError(try Validation.validateOrderSize(Decimal(-1)))
        
        // Test invalid order size (too small)
        XCTAssertThrowsError(try Validation.validateOrderSize(Decimal(0.00001)))
        
        // Test invalid order size (too large)
        XCTAssertThrowsError(try Validation.validateOrderSize(Decimal(10_000_000)))
    }
    
    func testAssetSymbolValidation() {
        // Test valid asset symbol
        XCTAssertNoThrow(try Validation.validateAssetSymbol("BTC"))
        XCTAssertNoThrow(try Validation.validateAssetSymbol("ETH-USD"))

        // Test invalid asset symbol (empty)
        XCTAssertThrowsError(try Validation.validateAssetSymbol(""))

        // Test invalid asset symbol (too long)
        XCTAssertThrowsError(try Validation.validateAssetSymbol(String(repeating: "A", count: 25)))
    }


    func testGetAllMids() async throws {
        let response = try await readOnlyClient.getAllMids()

        // Verify we have expected markets
        XCTAssertTrue(response.keys.contains("BTC"), "Should contain BTC")
        XCTAssertTrue(response.keys.contains("ETH"), "Should contain ETH")

        // Verify price format
        for (symbol, price) in response {
            XCTAssertFalse(symbol.isEmpty, "Symbol should not be empty")
            XCTAssertNotNil(Double(price.description), "Price should be valid number: \(price)")
            XCTAssertGreaterThan(Double(price.description) ?? 0, 0, "Price should be positive")
        }

        print("✅ Found \(response.count) markets")
    }

    func testGetMeta() async throws {
        let response = try await readOnlyClient.getMeta()

        // Verify structure
        XCTAssertGreaterThan(response.universe.count, 0, "Should have assets")

        // Verify first asset structure
        let firstAsset = response.universe[0]
        XCTAssertFalse(firstAsset.name.isEmpty, "Asset name should not be empty")
        XCTAssertGreaterThanOrEqual(firstAsset.szDecimals, 0, "Size decimals should be non-negative")
        XCTAssertGreaterThan(firstAsset.maxLeverage, 0, "Max leverage should be positive")

        print("✅ Found \(response.universe.count) perpetual assets")
    }

    func testGetSpotMeta() async throws {
        let response = try await readOnlyClient.getSpotMeta()

        // Verify structure
        XCTAssertGreaterThan(response.universe.count, 0, "Should have spot assets")

        // Verify first spot asset structure
        let firstAsset = response.universe[0]
        XCTAssertFalse(firstAsset.name.isEmpty, "Spot asset name should not be empty")
        XCTAssertGreaterThanOrEqual(firstAsset.szDecimals, 0, "Size decimals should be non-negative")

        print("✅ Found \(response.universe.count) spot assets")
    }

    func testGetUserStateWithTestAddress() async throws {
        let response = try await readOnlyClient.getUserState(address: testAddress)

        XCTAssertNotNil(response.assetPositions, "Should have assetPositions field")
        XCTAssertNotNil(response.crossMarginSummary, "Should have crossMarginSummary field")
        XCTAssertGreaterThanOrEqual(response.crossMaintenanceMarginUsed, 0, "Maintenance margin should be non-negative")
        XCTAssertGreaterThan(response.time, 0, "Time should be positive")

        // Verify margin summary structure
        let marginSummary = response.crossMarginSummary
        XCTAssertGreaterThanOrEqual(marginSummary.accountValue, 0, "Account value should be non-negative")
        XCTAssertGreaterThanOrEqual(marginSummary.totalMarginUsed, 0, "Total margin used should be non-negative")
        XCTAssertGreaterThanOrEqual(marginSummary.totalNtlPos, 0, "Total notional position should be non-negative")
        XCTAssertGreaterThanOrEqual(marginSummary.totalRawUsd, 0, "Total raw USD should be non-negative")

        print("✅ User state retrieved with \(response.assetPositions.count) positions")
    }

    func testGetOpenOrdersWithTestAddress() async throws {
        let response = try await readOnlyClient.getOpenOrders(address: testAddress)

        // Should not throw error even if no orders
        XCTAssertNotNil(response, "Response should not be nil")

        // Verify order structure if orders exist
        for order in response {
            XCTAssertFalse(order.coin.isEmpty, "Order coin should not be empty")
            XCTAssertGreaterThan(order.px, 0, "Price should be positive")
            XCTAssertGreaterThan(order.oid, 0, "Order ID should be positive")
            XCTAssertTrue([Side.buy, Side.sell].contains(order.side), "Side should be buy or sell")
            XCTAssertGreaterThan(order.sz, 0, "Size should be positive")
            XCTAssertGreaterThan(order.timestamp, 0, "Timestamp should be positive")
            XCTAssertGreaterThan(order.origSz, 0, "Original size should be positive")
        }

        print("✅ Found \(response.count) open orders")
    }

    func testGetUserFillsWithTestAddress() async throws {
        let response = try await readOnlyClient.getUserFills(address: testAddress)

        XCTAssertNotNil(response, "Response should not be nil")

        // Verify fill structure if fills exist
        for fill in response {
            XCTAssertFalse(fill.coin.isEmpty, "Fill coin should not be empty")
            XCTAssertGreaterThan(fill.px, 0, "Fill price should be positive")
            XCTAssertGreaterThan(fill.sz, 0, "Fill size should be positive")
            XCTAssertFalse(fill.side.isEmpty, "Fill side should not be empty")
            XCTAssertGreaterThan(fill.time, 0, "Fill time should be positive")
            XCTAssertGreaterThan(fill.startPosition, 0, "Start position should be non-negative")
            XCTAssertFalse(fill.dir.isEmpty, "Direction should not be empty")
            XCTAssertGreaterThanOrEqual(fill.closedPnl, 0, "Closed PnL should be non-negative")
            XCTAssertFalse(fill.hash.isEmpty, "Hash should not be empty")
            XCTAssertGreaterThan(fill.oid, 0, "Order ID should be positive")
            XCTAssertGreaterThanOrEqual(fill.fee, 0, "Fee should be non-negative")
            XCTAssertGreaterThan(fill.tid, 0, "Trade ID should be positive")
        }

        print("✅ Found \(response.count) fills")
    }

    func testGetUserFillsByTime() async throws {
        let startTime = 1683245555699 
        let endTime = 1683245884863

        let response = try await readOnlyClient.getUserFillsByTime(
            user: testAddress,
            startTime: startTime,
            endTime: endTime
        )

        XCTAssertNotNil(response, "Response should not be nil")

        // Verify time range if fills exist
        for fill in response {
            XCTAssertGreaterThanOrEqual(fill.time, startTime, "Fill time should be >= start time")
            XCTAssertLessThanOrEqual(fill.time, endTime, "Fill time should be <= end time")
        }

        print("✅ Found \(response.count) fills in time range")
    }
}
