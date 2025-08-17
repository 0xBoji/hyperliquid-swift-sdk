import Foundation
import HyperliquidSwift

/// Example demonstrating agent wallet management
/// This includes creating and approving agent wallets for automated trading
class AgentManagementExample {
    
    static func main() async {
        do {
            // Setup client with testnet configuration
            let config = try ExampleUtils.loadConfig()
            let client = try await ExampleUtils.setupClient(config: config, useTestnet: true)
            
            print("🤖 Agent Management Example")
            print("===========================")
            
            // Step 1: Approve a new agent wallet
            print("🔑 Creating and approving new agent wallet...")
            
            let (agentResponse, agentKey) = try await client.approveAgent(agentName: "TradingBot_v1")
            
            print("✅ Agent approval result:")
            print(agentResponse)
            print("🔐 Agent private key: \(agentKey)")
            print("⚠️  IMPORTANT: Store this private key securely!")
            
            // Step 2: Display agent information
            if let response = agentResponse.dictionary,
               let status = response["status"] as? String,
               status == "ok" {
                
                print("\n📊 Agent Information:")
                print("- Agent Name: TradingBot_v1")
                print("- Private Key: \(agentKey)")
                print("- Status: Approved and ready for trading")
                
                // Step 3: Demonstrate agent usage (conceptual)
                print("\n🎯 Next Steps:")
                print("1. Store the agent private key securely")
                print("2. Use the agent key to create a new HyperliquidClient")
                print("3. The agent can now trade on behalf of the main account")
                print("4. Set appropriate permissions and limits for the agent")
                
                // Example of how to use the agent key (don't actually do this in production)
                print("\n💡 Usage Example:")
                print("let agentClient = try HyperliquidClient.trading(")
                print("    privateKeyHex: \"\(agentKey)\",")
                print("    environment: .testnet")
                print(")")
                
            } else {
                print("⚠️ Agent approval may have failed. Check the response.")
            }
            
            print("🎯 Agent management example completed successfully")
            
        } catch {
            print("❌ Error with agent management: \(error)")
        }
    }
}

// MARK: - Usage Instructions
/*
 To run this example:
 
 1. Ensure you have a valid config.json file with your wallet configuration
 2. Make sure your account has permissions to create agents
 3. Run the example:
    ```
    swift run AgentManagementExample
    ```
 
 This example demonstrates:
 - Creating and approving agent wallets
 - Generating secure private keys for agents
 - Setting up automated trading infrastructure
 
 Important Security Notes:
 - Agent private keys should be stored securely
 - Agents inherit permissions from the main account
 - Consider implementing additional security measures for production use
 - Monitor agent activity and set appropriate limits
 
 Use Cases:
 - Automated trading bots
 - Market making strategies
 - Portfolio rebalancing
 - Risk management systems
 */
