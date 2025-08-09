import Foundation
import HyperliquidSwift

public struct ExampleUtils {
    
    /// Configuration structure 
    public struct Config: Codable {
        public let secretKey: String
        public let accountAddress: String
        public let environment: String
        
        enum CodingKeys: String, CodingKey {
            case secretKey = "secret_key"
            case accountAddress = "account_address"
            case environment
        }
    }
    
    /// Returns (address, client) tuple for examples
    public static func setup(environment: HyperliquidEnvironment? = nil) async throws -> (String, HyperliquidClient) {
        // Load config from config.json
        let config = try loadConfig()
        
        // Validate secret key
        guard !config.secretKey.isEmpty else {
            throw ExampleError.missingSecretKey("Please set secret_key in config.json")
        }
        
        // Determine environment
        let env = environment ?? (config.environment == "mainnet" ? .mainnet : .testnet)
        
        // Create client
        let client = try HyperliquidClient.trading(
            privateKeyHex: config.secretKey,
            environment: env
        )
        
        // Determine address
        let address: String
        if !config.accountAddress.isEmpty {
            address = config.accountAddress
            print("Running with account address: \(address)")
            // Note: walletAddress is actor-isolated, so we'll skip this check for now
            print("Using configured account address")
        } else {
            // For now, use the configured address or throw error
            throw ExampleError.invalidConfiguration("Please specify account_address in config.json")
        }
        
        // Verify account has equity 
        let userState = try await client.getUserState(address: address)
        let accountValue = Double(String(describing: userState.crossMarginSummary.accountValue)) ?? 0.0
        
        if accountValue == 0 {
            let envName = env == .mainnet ? "hyperliquid.xyz" : "hyperliquid-testnet.xyz"
            let errorMessage = """
            Not running the example because the provided account has no equity.
            No accountValue:
            If you think this is a mistake, make sure that \(address) has a balance on \(envName).
            If address shown is your API wallet address, update the config to specify the address of your account, not the address of the API wallet.
            """
            throw ExampleError.noEquity(errorMessage)
        }
        
        print("Account value: $\(userState.crossMarginSummary.accountValue)")
        
        return (address, client)
    }
    
    /// Load configuration from config.json file
    private static func loadConfig() throws -> Config {
        // Get the directory where the executable is located
        let executablePath = CommandLine.arguments[0]
        let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
        
        // Look for config.json in the same directory as the executable
        let configPath = executableDir.appendingPathComponent("config.json")
        
        // Also try Examples directory relative to current working directory
        let alternativeConfigPath = URL(fileURLWithPath: "Examples/config.json")
        
        var configURL: URL
        if FileManager.default.fileExists(atPath: configPath.path) {
            configURL = configPath
        } else if FileManager.default.fileExists(atPath: alternativeConfigPath.path) {
            configURL = alternativeConfigPath
        } else {
            throw ExampleError.configNotFound("""
            Config file not found. Please:
            1. Copy Examples/config.json.example to Examples/config.json
            2. Fill in your secret_key and optionally account_address
            3. Run the example again
            """)
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(Config.self, from: data)
            return config
        } catch {
            throw ExampleError.invalidConfig("Failed to parse config.json: \(error.localizedDescription)")
        }
    }
    
    /// Validate that the account has sufficient balance for trading
    public static func validateAccountForTrading(_ client: HyperliquidClient, address: String) async throws {
        let userState = try await client.getUserState(address: address)
        let accountValue = Double(String(describing: userState.crossMarginSummary.accountValue)) ?? 0.0
        
        guard accountValue > 0 else {
            throw ExampleError.noEquity("Account has no equity. Please deposit funds before running trading examples.")
        }
        
        print("✅ Account validated - Balance: $\(userState.crossMarginSummary.accountValue)")
    }
    
    /// Print account summary in a nice format
    public static func printAccountSummary(_ client: HyperliquidClient, address: String) async throws {
        print("\n📊 Account Summary")
        print("==================")
        
        let userState = try await client.getUserState(address: address)
        
        print("Address: \(address)")
        print("Account Value: $\(userState.crossMarginSummary.accountValue)")
        print("Total Margin Used: $\(userState.crossMarginSummary.totalMarginUsed)")
        print("Maintenance Margin: $\(userState.crossMaintenanceMarginUsed)")
        print("Positions: \(userState.assetPositions.count)")
        
        if !userState.assetPositions.isEmpty {
            print("\nPositions:")
            for position in userState.assetPositions {
                let entryPxStr = position.position.entryPx != nil ? String(describing: position.position.entryPx!) : "N/A"
                print("  \(position.position.coin): \(position.position.szi) @ $\(entryPxStr) (PnL: $\(position.position.unrealizedPnl))")
            }
        }
        
        let openOrders = try await client.getOpenOrders(address: address)
        print("Open Orders: \(openOrders.count)")
        
        if !openOrders.isEmpty {
            print("\nOpen Orders:")
            for order in openOrders.prefix(5) {
                let side = order.side == .buy ? "Buy" : "Sell"
                print("  \(order.coin): \(side) \(order.sz) @ $\(order.limitPx)")
            }
            if openOrders.count > 5 {
                print("  ... and \(openOrders.count - 5) more")
            }
        }
    }
    
    /// Print market data summary
    public static func printMarketSummary(_ client: HyperliquidClient) async throws {
        print("\n📈 Market Summary")
        print("=================")
        
        let mids = try await client.getAllMids()
        print("Active Markets: \(mids.count)")
        
        // Show top markets by price
        let sortedMarkets = mids.sorted { Double(String(describing: $0.value)) ?? 0 > Double(String(describing: $1.value)) ?? 0 }
        print("\nTop Markets by Price:")
        for (symbol, price) in sortedMarkets.prefix(5) {
            print("  \(symbol): $\(price)")
        }
        
        let meta = try await client.getMeta()
        print("\nTotal Assets: \(meta.universe.count)")
        
        print("\nSample Assets:")
        for asset in meta.universe.prefix(3) {
            print("  \(asset.name): \(asset.szDecimals) decimals, max leverage: \(asset.maxLeverage)x")
        }
    }
}

// MARK: - Error Types

public enum ExampleError: Error, LocalizedError {
    case configNotFound(String)
    case invalidConfig(String)
    case missingSecretKey(String)
    case invalidConfiguration(String)
    case noEquity(String)
    
    public var errorDescription: String? {
        switch self {
        case .configNotFound(let message),
             .invalidConfig(let message),
             .missingSecretKey(let message),
             .invalidConfiguration(let message),
             .noEquity(let message):
            return message
        }
    }
}
