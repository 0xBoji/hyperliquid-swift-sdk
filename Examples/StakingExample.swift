import Foundation
import HyperliquidSwift

/// Staking Operations Example
/// Similar to Python SDK's basic_staking.py
public struct StakingExample {
    
    private let client: HyperliquidClient
    private let userAddress: String
    
    public init(client: HyperliquidClient, userAddress: String) {
        self.client = client
        self.userAddress = userAddress
    }
    
    /// Run staking example
    public func run() async throws {
        print("🏦 Starting Staking Operations Example")
        print("User Address: \(userAddress)")
        
        // Get user staking summary
        print("\n📊 Getting Staking Summary...")
        let stakingSummary = try await client.getUserStakingSummary(address: userAddress)
        print("Staking Summary:")
        print("  Response: \(stakingSummary)")
        
        // Get user staking delegations
        print("\n🤝 Getting Staking Delegations...")
        let delegations = try await client.getUserStakingDelegations(address: userAddress)
        print("Staking Delegations:")
        print("  Response: \(delegations)")
        
        // Get user staking rewards
        print("\n🎁 Getting Staking Rewards...")
        let rewards = try await client.getUserStakingRewards(address: userAddress)
        print("Most Recent Staking Rewards:")
        print("  Response: \(rewards)")
        
        // Example: Delegate tokens to a validator
        print("\n💸 Example: Token Delegation...")
        let validatorAddress = "0x742d35Cc6634C0532925a3b8D4C9db96c4b4Db45"
        let delegationAmount = 1000000000000000000 // 1 token in wei
        
        print("  Delegating \(delegationAmount) wei to validator: \(validatorAddress)")
        let delegateResult = try await client.tokenDelegate(
            validator: validatorAddress,
            wei: delegationAmount,
            isUndelegate: false
        )
        print("  ✅ Delegation result: \(delegateResult)")
        
        // Example: Undelegate tokens
        print("\n💸 Example: Token Undelegation...")
        print("  Undelegating \(delegationAmount) wei from validator: \(validatorAddress)")
        let undelegateResult = try await client.tokenDelegate(
            validator: validatorAddress,
            wei: delegationAmount,
            isUndelegate: true
        )
        print("  ✅ Undelegation result: \(undelegateResult)")
        
        print("\n🎉 Staking operations completed!")
    }
}

// MARK: - Main Function
@main
struct StakingExampleMain {
    static func main() async throws {
        // Simple setup for demo
        let userAddress = "0x1234567890123456789012345678901234567890"
        let client = try HyperliquidClient(
            privateKeyHex: "your_private_key_here",
            environment: .testnet
        )
        
        let example = StakingExample(client: client, userAddress: userAddress)
        try await example.run()
    }
}
