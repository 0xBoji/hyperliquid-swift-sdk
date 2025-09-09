import Foundation
import HyperliquidSwift

/// Spot Trading Example
/// Similar to Python SDK's basic_spot_order.py
public struct SpotTradingExample {
    
    private let client: HyperliquidClient
    private let userAddress: String
    
    public init(client: HyperliquidClient, userAddress: String) {
        self.client = client
        self.userAddress = userAddress
    }
    
    /// Run spot trading example
    public func run() async throws {
        print("🪙 Starting Spot Trading Example")
        print("User Address: \(userAddress)")
        
        // Get spot user state
        let spotUserState = try await client.getSpotUserState(user: userAddress)
        print("📊 Spot Account State:")
        print("  Response: \(spotUserState)")
        
        // Place a spot buy order (example with USDC)
        print("\n💸 Placing Spot Buy Order...")
        print("  Note: This would require spotOrder method implementation")
        
        // Place a spot sell order (example with HYPE)
        print("\n💸 Placing Spot Sell Order...")
        print("  Note: This would require spotOrder method implementation")
        
        // Get updated spot user state
        let updatedSpotState = try await client.getSpotUserState(user: userAddress)
        print("\n📊 Updated Spot Account State:")
        print("  Response: \(updatedSpotState)")
        
        print("\n✅ Spot trading example completed!")
    }
    
}

// MARK: - Main Function
@main
struct SpotTradingExampleMain {
    static func main() async throws {
        // Simple setup for demo
        let userAddress = "0x1234567890123456789012345678901234567890"
        let client = try HyperliquidClient(
            privateKeyHex: "your_private_key_here",
            environment: .testnet
        )
        
        let example = SpotTradingExample(client: client, userAddress: userAddress)
        try await example.run()
    }
}
