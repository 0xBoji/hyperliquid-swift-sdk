import XCTest
@testable import HyperliquidSwift

final class HyperliquidClientTests: XCTestCase {
    
    func testReadOnlyClientCreation() throws {
        let client = try HyperliquidClient.readOnly(environment: .testnet)
        XCTAssertFalse(client.isAuthenticated)
        XCTAssertNil(client.walletAddress)
    }
    
    func testTradingClientCreation() throws {
        let privateKeyHex = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        let client = try HyperliquidClient.trading(privateKeyHex: privateKeyHex, environment: .testnet)
        XCTAssertTrue(client.isAuthenticated)
        XCTAssertNotNil(client.walletAddress)
    }
    
    func testInvalidPrivateKey() {
        XCTAssertThrowsError(try HyperliquidClient.trading(privateKeyHex: "invalid", environment: .testnet)) { error in
            XCTAssertTrue(error is HyperliquidError)
        }
    }
    
    func testEnvironmentConfiguration() throws {
        let mainnetClient = try HyperliquidClient.readOnly(environment: .mainnet)
        XCTAssertEqual(mainnetClient.environment, .mainnet)
        
        let testnetClient = try HyperliquidClient.readOnly(environment: .testnet)
        XCTAssertEqual(testnetClient.environment, .testnet)
    }
}
