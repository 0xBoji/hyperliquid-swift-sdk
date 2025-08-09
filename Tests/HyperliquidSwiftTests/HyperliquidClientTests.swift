import XCTest
@testable import HyperliquidSwift

final class HyperliquidClientTests: XCTestCase {
    
    func testReadOnlyClientCreation() async throws {
        let client = try HyperliquidClient.readOnly(environment: .testnet)
        let isAuth = await client.isAuthenticated
        XCTAssertFalse(isAuth)
        let walletAddr = await client.walletAddress
        XCTAssertNil(walletAddr)
    }
    
    func testTradingClientCreation() async throws {
        let privateKeyHex = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let client = try HyperliquidClient.trading(privateKeyHex: privateKeyHex, environment: .testnet)
        let isAuth = await client.isAuthenticated
        XCTAssertTrue(isAuth)
        let walletAddr = await client.walletAddress
        XCTAssertNotNil(walletAddr)
    }
    
    func testInvalidPrivateKey() {
        XCTAssertThrowsError(try HyperliquidClient.trading(privateKeyHex: "invalid", environment: .testnet)) { error in
            XCTAssertTrue(error is HyperliquidError)
        }
    }
    
    func testEnvironmentConfiguration() async throws {
        let mainnetClient = try HyperliquidClient.readOnly(environment: .mainnet)
        let mainnetEnv = await mainnetClient.environment
        XCTAssertEqual(mainnetEnv, .mainnet)

        let testnetClient = try HyperliquidClient.readOnly(environment: .testnet)
        let testnetEnv = await testnetClient.environment
        XCTAssertEqual(testnetEnv, .testnet)
    }
}
