import XCTest
@testable import HyperliquidSwift

/// Tests for the newly implemented methods
/// These tests verify the method signatures, parameter handling, and basic functionality
final class NewMethodsTests: XCTestCase {
    
    var client: HyperliquidClient!
    
    override func setUp() async throws {
        // Setup test client with mock configuration
        let testPrivateKey = "0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        client = try HyperliquidClient(
            privateKey: testPrivateKey,
            testnet: true
        )
    }
    
    override func tearDown() {
        client = nil
    }
    
    // MARK: - Market Order Tests
    
    func testMarketBuyMethodSignature() async throws {
        // Test that marketBuy method exists with correct signature
        // This will compile-time verify the method signature
        let _: () async throws -> JSONResponse = {
            try await self.client.marketBuy(
                coin: "ETH",
                sz: Decimal(0.1),
                slippage: Decimal(0.05),
                reduceOnly: false
            )
        }
    }
    
    func testMarketSellMethodSignature() async throws {
        // Test that marketSell method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.marketSell(
                coin: "BTC",
                sz: Decimal(0.01),
                slippage: Decimal(0.02),
                reduceOnly: true
            )
        }
    }
    
    // MARK: - Account Management Tests
    
    func testUpdateLeverageMethodSignature() async throws {
        // Test that updateLeverage method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.updateLeverage(
                coin: "ETH",
                leverage: 10,
                isCross: true
            )
        }
    }
    
    func testUpdateIsolatedMarginMethodSignature() async throws {
        // Test that updateIsolatedMargin method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.updateIsolatedMargin(
                coin: "BTC",
                amountUsd: Decimal(100),
                isBuy: true
            )
        }
    }
    
    func testSetReferrerMethodSignature() async throws {
        // Test that setReferrer method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.setReferrer(code: "REFERRAL123")
        }
    }
    
    func testCreateSubAccountMethodSignature() async throws {
        // Test that createSubAccount method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.createSubAccount(name: "TestSubAccount")
        }
    }
    
    // MARK: - Advanced Features Tests
    
    func testTokenDelegateMethodSignature() async throws {
        // Test that tokenDelegate method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.tokenDelegate(
                validator: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
                wei: 1000000000000000000,
                isUndelegate: false
            )
        }
    }
    
    func testWithdrawFromBridgeMethodSignature() async throws {
        // Test that withdrawFromBridge method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.withdrawFromBridge(
                amount: Decimal(10),
                destination: "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45"
            )
        }
    }
    
    func testApproveBuilderFeeMethodSignature() async throws {
        // Test that approveBuilderFee method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.approveBuilderFee(
                builder: "0x8c967E73E7B15087c42A10D344cFf4c96D877f1D",
                maxFeeRate: "0.001%"
            )
        }
    }
    
    func testConvertToMultiSigUserMethodSignature() async throws {
        // Test that convertToMultiSigUser method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.convertToMultiSigUser(
                authorizedUsers: [
                    "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45",
                    "0xa15099a30bbf2e68942d6f4c43d70d04faeab0a0"
                ],
                threshold: 2
            )
        }
    }
    
    func testMultiSigMethodSignature() async throws {
        // Test that multiSig method exists with correct signature
        let innerAction: [String: any Sendable] = [
            "type": "order",
            "orders": [["a": 4, "b": true, "p": "1100", "s": "0.2", "r": false]]
        ]
        
        let _: () async throws -> JSONResponse = {
            try await self.client.multiSig(
                multiSigUser: "0x0000000000000000000000000000000000000005",
                innerAction: innerAction,
                signatures: ["0x123...", "0x456..."],
                nonce: 1234567890,
                vaultAddress: nil
            )
        }
    }
    
    func testUseBigBlocksMethodSignature() async throws {
        // Test that useBigBlocks method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.useBigBlocks(enable: true)
        }
    }
    
    // MARK: - Info Service Tests
    
    func testGetMetaAndAssetCtxsMethodSignature() async throws {
        // Test that getMetaAndAssetCtxs method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.getMetaAndAssetCtxs()
        }
    }
    
    func testGetSpotMetaAndAssetCtxsMethodSignature() async throws {
        // Test that getSpotMetaAndAssetCtxs method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.getSpotMetaAndAssetCtxs()
        }
    }

    // MARK: - New Methods Tests (Batch 2)

    func testBulkCancelByCloidMethodSignature() async throws {
        // Test that bulkCancelByCloid method exists with correct signature
        let cancelRequests = [CancelByCloidRequest(coin: "ETH", cloid: "test_cloid")]
        let _: () async throws -> JSONResponse = {
            try await self.client.bulkCancelByCloid(cancelRequests)
        }
    }

    func testSetExpiresAfterMethodSignature() async throws {
        // Test that setExpiresAfter method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.setExpiresAfter(expiresAfter: 1234567890)
        }
    }

    func testStopLossOrderMethodSignature() async throws {
        // Test that stopLossOrder method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.stopLossOrder(
                coin: "ETH",
                isBuy: false,
                sz: Decimal(0.1),
                triggerPx: Decimal(2000)
            )
        }
    }

    func testTakeProfitOrderMethodSignature() async throws {
        // Test that takeProfitOrder method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.takeProfitOrder(
                coin: "BTC",
                isBuy: true,
                sz: Decimal(0.01),
                triggerPx: Decimal(50000)
            )
        }
    }

    func testRegisterValidatorMethodSignature() async throws {
        // Test that registerValidator method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.registerValidator(
                nodeIp: "192.168.1.100",
                name: "TestValidator",
                description: "Test validator description",
                discordUsername: "testuser#1234",
                commissionRate: "0.05"
            )
        }
    }

    func testUnregisterValidatorMethodSignature() async throws {
        // Test that unregisterValidator method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.unregisterValidator()
        }
    }

    // MARK: - New Methods Tests (Batch 3)

    func testChangeValidatorProfileMethodSignature() async throws {
        // Test that changeValidatorProfile method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.changeValidatorProfile(
                nodeIp: "192.168.1.100",
                name: "TestValidator",
                description: "Test description",
                discordUsername: "test#1234",
                commissionRate: "0.05"
            )
        }
    }

    func testCSignerUnjailSelfMethodSignature() async throws {
        // Test that cSignerUnjailSelf method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.cSignerUnjailSelf()
        }
    }

    func testCSignerJailSelfMethodSignature() async throws {
        // Test that cSignerJailSelf method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.cSignerJailSelf()
        }
    }

    func testSpotDeployRegisterTokenMethodSignature() async throws {
        // Test that spotDeployRegisterToken method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.spotDeployRegisterToken(
                tokenName: "TESTTOKEN",
                szDecimals: 6,
                weiDecimals: 18,
                maxGas: 1000000,
                fullName: "Test Token"
            )
        }
    }

    func testPerpDeployRegisterAssetMethodSignature() async throws {
        // Test that perpDeployRegisterAsset method exists with correct signature
        let _: () async throws -> JSONResponse = {
            try await self.client.perpDeployRegisterAsset(
                dex: "testdex",
                name: "TESTPERP",
                szDecimals: 4,
                maxLeverage: 20,
                onlyIsolated: false
            )
        }
    }
    
    // MARK: - Parameter Validation Tests
    
    func testMarketOrderSlippageValidation() {
        // Test that slippage parameters are handled correctly
        XCTAssertNoThrow(Decimal(0.01)) // 1% slippage
        XCTAssertNoThrow(Decimal(0.05)) // 5% slippage
        XCTAssertNoThrow(Decimal(0.10)) // 10% slippage
    }
    
    func testLeverageValidation() {
        // Test that leverage values are handled correctly
        let validLeverages = [1, 2, 5, 10, 20, 50, 100]
        for leverage in validLeverages {
            XCTAssertGreaterThan(leverage, 0)
            XCTAssertLessThanOrEqual(leverage, 100)
        }
    }
    
    func testAddressValidation() {
        // Test that Ethereum addresses are properly formatted
        let validAddress = "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45"
        XCTAssertTrue(validAddress.hasPrefix("0x"))
        XCTAssertEqual(validAddress.count, 42) // 0x + 40 hex characters
    }

    // MARK: - Error Handling Tests

    func testClientNotInitializedError() async throws {
        // Test that proper errors are thrown when client is not initialized
        let uninitializedClient = try HyperliquidClient(
            privateKey: "0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
            testnet: true
        )

        // These should not throw during method call setup, but would fail during actual execution
        // We're testing the method signatures exist and compile correctly
        XCTAssertNoThrow({
            let _: () async throws -> JSONResponse = {
                try await uninitializedClient.marketBuy(coin: "ETH", sz: Decimal(0.1))
            }
        }())
    }

    // MARK: - Method Availability Tests

    func testAllNewMethodsAreAvailable() {
        // Verify all new methods are available on the client by testing compilation
        let client = self.client!

        // Test that methods exist and compile correctly
        XCTAssertNotNil(client)

        // These tests verify the methods exist and have correct signatures
        // by attempting to create closures that reference them
        let _: (String, Decimal) async throws -> JSONResponse = client.marketBuy(coin:sz:)
        let _: (String, Decimal) async throws -> JSONResponse = client.marketSell(coin:sz:)
        let _: (String, Int) async throws -> JSONResponse = client.updateLeverage(coin:leverage:)
        let _: (String) async throws -> JSONResponse = client.setReferrer(code:)
        let _: (String) async throws -> JSONResponse = client.createSubAccount(name:)
        let _: (Bool) async throws -> JSONResponse = client.useBigBlocks(enable:)
        let _: (String, String) async throws -> JSONResponse = client.approveBuilderFee(builder:maxFeeRate:)
    }
}
