import XCTest
@testable import HyperliquidSwift

/// Mock tests for Hyperliquid Swift SDK
/// These tests use mock data and don't make real API calls
final class MockTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func testUserStateDecoding() throws {
        // Test UserState model decoding
        let json = """
        {
            "assetPositions": [
                {
                    "position": {
                        "coin": "BTC",
                        "entryPx": "50000.0",
                        "leverage": {
                            "type": "cross",
                            "value": 1
                        },
                        "liquidationPx": null,
                        "marginUsed": "1000.0",
                        "maxLeverage": 100,
                        "positionValue": "50000.0",
                        "returnOnEquity": "0.0",
                        "szi": "1.0",
                        "unrealizedPnl": "0.0"
                    },
                    "type": "oneWay"
                }
            ],
            "crossMarginSummary": {
                "accountValue": "51000.0",
                "totalMarginUsed": "1000.0",
                "totalNtlPos": "50000.0",
                "totalRawUsd": "51000.0"
            },
            "crossMaintenanceMarginUsed": "500.0",
            "time": 1234567890
        }
        """.data(using: .utf8)!
        
        let userState = try JSONDecoder().decode(UserState.self, from: json)
        
        XCTAssertEqual(userState.assetPositions.count, 1)
        XCTAssertEqual(userState.assetPositions[0].position.coin, "BTC")
        XCTAssertEqual(userState.assetPositions[0].position.szi, "1.0")
        XCTAssertEqual(userState.crossMarginSummary.accountValue, "51000.0")
        XCTAssertEqual(userState.crossMaintenanceMarginUsed, 500.0)
    }
    
    func testMetaDecoding() throws {
        // Test Meta model decoding
        let json = """
        {
            "universe": [
                {
                    "name": "BTC",
                    "szDecimals": 5,
                    "maxLeverage": 100,
                    "onlyIsolated": false
                },
                {
                    "name": "ETH", 
                    "szDecimals": 4,
                    "maxLeverage": 50,
                    "onlyIsolated": false
                }
            ]
        }
        """.data(using: .utf8)!
        
        let meta = try JSONDecoder().decode(Meta.self, from: json)
        
        XCTAssertEqual(meta.universe.count, 2)
        XCTAssertEqual(meta.universe[0].name, "BTC")
        XCTAssertEqual(meta.universe[0].szDecimals, 5)
        XCTAssertEqual(meta.universe[1].name, "ETH")
        XCTAssertEqual(meta.universe[1].szDecimals, 4)
    }
    
    func testOpenOrderDecoding() throws {
        // Test OpenOrder model decoding
        let json = """
        {
            "coin": "BTC",
            "limitPx": "50000.0",
            "oid": 12345,
            "side": "B",
            "sz": "1.0",
            "timestamp": 1234567890,
            "tif": "Gtc",
            "triggerCondition": "tp",
            "triggerPx": "55000.0",
            "children": [],
            "isPositionTpsl": false,
            "isTrigger": true,
            "orderType": "limit",
            "origSz": "1.0",
            "reduceOnly": false,
            "cloid": "client123"
        }
        """.data(using: .utf8)!
        
        let order = try JSONDecoder().decode(OpenOrder.self, from: json)
        
        XCTAssertEqual(order.coin, "BTC")
        XCTAssertEqual(order.limitPx, "50000.0")
        XCTAssertEqual(order.oid, 12345)
        XCTAssertEqual(order.side, "B")
        XCTAssertEqual(order.sz, "1.0")
        XCTAssertEqual(order.cloid, "client123")
    }
    
    func testFillDecoding() throws {
        // Test Fill model decoding
        let json = """
        {
            "coin": "BTC",
            "px": "50000.0",
            "sz": "1.0",
            "side": "B",
            "time": 1234567890,
            "startPosition": "0.0",
            "dir": "Open Long",
            "closedPnl": "0.0",
            "hash": "0xabcdef123456",
            "oid": 12345,
            "crossed": true,
            "fee": "25.0",
            "liquidation": false,
            "tid": 67890
        }
        """.data(using: .utf8)!

        let fill = try JSONDecoder().decode(Fill.self, from: json)
        
        XCTAssertEqual(fill.coin, "BTC")
        XCTAssertEqual(fill.px, Decimal(string: "50000.0"))
        XCTAssertEqual(fill.sz, Decimal(string: "1.0"))
        XCTAssertEqual(fill.side, Side.buy)
        XCTAssertEqual(fill.oid, 12345)
        XCTAssertEqual(fill.fee, Decimal(string: "25.0"))
        XCTAssertEqual(fill.tid, 67890)
    }
    
    func testReferralStateDecoding() throws {
        // Test ReferralState model decoding
        let json = """
        {
            "state": "active",
            "code": "TESTCODE123"
        }
        """.data(using: .utf8)!
        
        let referralState = try JSONDecoder().decode(ReferralState.self, from: json)
        
        XCTAssertEqual(referralState.state, "active")
        XCTAssertEqual(referralState.code, "TESTCODE123")
    }
    
    func testSubAccountDecoding() throws {
        // Test SubAccount model decoding
        let json = """
        {
            "subAccountUser": "0x1234567890123456789012345678901234567890",
            "clearinghouseState": {
                "assetPositions": [],
                "crossMarginSummary": {
                    "accountValue": "1000.0",
                    "totalMarginUsed": "0.0",
                    "totalNtlPos": "0.0",
                    "totalRawUsd": "1000.0"
                },
                "crossMaintenanceMarginUsed": "0.0",
                "time": 1234567890
            }
        }
        """.data(using: .utf8)!
        
        let subAccount = try JSONDecoder().decode(SubAccount.self, from: json)
        
        XCTAssertEqual(subAccount.subAccountUser, "0x1234567890123456789012345678901234567890")
        XCTAssertEqual(subAccount.clearinghouseState.crossMarginSummary.accountValue, "1000.0")
    }
    
    // MARK: - JSONResponse Tests
    
    func testJSONResponseDecoding() throws {
        // Test JSONResponse with dictionary
        let dictJson = """
        {
            "key1": "value1",
            "key2": 123,
            "key3": true,
            "key4": null
        }
        """.data(using: .utf8)!
        
        let jsonResponse = try JSONDecoder().decode(JSONResponse.self, from: dictJson)
        let dict = jsonResponse.dictionary
        
        XCTAssertEqual(dict["key1"] as? String, "value1")
        XCTAssertEqual(dict["key2"] as? Int, 123)
        XCTAssertEqual(dict["key3"] as? Bool, true)
        XCTAssertTrue(dict["key4"] is NSNull)
    }
    
    func testJSONResponseArrayDecoding() throws {
        // Test JSONResponse with array
        let arrayJson = """
        ["item1", 123, true, null]
        """.data(using: .utf8)!
        
        let jsonResponse = try JSONDecoder().decode(JSONResponse.self, from: arrayJson)
        let array = jsonResponse.array
        
        XCTAssertEqual(array.count, 4)
        XCTAssertEqual(array[0] as? String, "item1")
        XCTAssertEqual(array[1] as? Int, 123)
        XCTAssertEqual(array[2] as? Bool, true)
        XCTAssertTrue(array[3] is NSNull)
    }
    
    // MARK: - Error Tests
    
    func testHyperliquidErrorTypes() {
        // Test different error types
        let networkError = HyperliquidError.networkError("Network failed")
        let authError = HyperliquidError.authenticationRequired("Auth required")
        let keyError = HyperliquidError.invalidPrivateKey("Invalid key")
        let requestError = HyperliquidError.requestFailed(statusCode: 400, message: "Bad request")
        
        // Test error descriptions
        XCTAssertTrue(networkError.localizedDescription.contains("Network failed"))
        XCTAssertTrue(authError.localizedDescription.contains("Auth required"))
        XCTAssertTrue(keyError.localizedDescription.contains("Invalid key"))
        XCTAssertTrue(requestError.localizedDescription.contains("Bad request"))
        
        // Test error codes
        XCTAssertEqual(networkError.errorCode, Constants.ErrorCodes.networkError)
        XCTAssertEqual(authError.errorCode, Constants.ErrorCodes.authenticationRequired)
        XCTAssertEqual(keyError.errorCode, Constants.ErrorCodes.invalidPrivateKey)
        XCTAssertEqual(requestError.errorCode, Constants.ErrorCodes.networkError)
    }
    
    // MARK: - Utility Tests
    
    func testPrivateKeyCreation() throws {
        // Test PrivateKey creation
        let validKey = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        let privateKey = try PrivateKey(hex: validKey)
        
        XCTAssertNotNil(privateKey)
        
        // Test wallet address generation (placeholder)
        let address = privateKey.walletAddress
        XCTAssertTrue(address.hasPrefix("0x"))
        XCTAssertEqual(address.count, 42) // 0x + 40 hex chars
    }
    
    func testDataHexExtension() {
        // Test Data hex extension
        let hexString = "deadbeef"
        let data = Data(hex: hexString)
        
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, 4) // 4 bytes
        
        // Test invalid hex
        let invalidHex = "invalid"
        let invalidData = Data(hex: invalidHex)
        XCTAssertNil(invalidData)
    }
    
    func testCharacterHexExtension() {
        // Test Character hex extension
        XCTAssertTrue(Character("a").isHexDigit)
        XCTAssertTrue(Character("F").isHexDigit)
        XCTAssertTrue(Character("9").isHexDigit)
        XCTAssertFalse(Character("g").isHexDigit)
        XCTAssertFalse(Character("z").isHexDigit)
    }
}
