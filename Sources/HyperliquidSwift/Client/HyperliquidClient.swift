import Foundation

/// Main client for interacting with Hyperliquid API
public actor HyperliquidClient {
    
    // MARK: - Properties
    
    public let environment: HyperliquidEnvironment
    public let infoService: InfoService
    private let privateKey: PrivateKey?
    
    /// Wallet address (available when using authenticated client)
    public var walletAddress: String? {
        return privateKey?.walletAddress
    }
    
    // MARK: - Initialization
    
    /// Initialize read-only client (no trading capabilities)
    public init(environment: HyperliquidEnvironment = .mainnet) throws {
        self.environment = environment
        self.infoService = try InfoService(environment: environment)
        self.privateKey = nil
    }
    
    /// Initialize authenticated client with trading capabilities
    public init(privateKeyHex: String, environment: HyperliquidEnvironment = .mainnet) throws {
        self.environment = environment
        self.infoService = try InfoService(environment: environment)
        self.privateKey = try PrivateKey(hex: privateKeyHex)
    }
    
    // MARK: - Factory Methods
    
    /// Create a read-only client for market data
    public static func readOnly(environment: HyperliquidEnvironment = .mainnet) throws -> HyperliquidClient {
        return try HyperliquidClient(environment: environment)
    }
    
    /// Create an authenticated client for trading
    public static func trading(privateKeyHex: String, environment: HyperliquidEnvironment = .mainnet) throws -> HyperliquidClient {
        return try HyperliquidClient(privateKeyHex: privateKeyHex, environment: environment)
    }
    
    // MARK: - Market Data Methods
    
    /// Get all mid prices
    public func getAllMids() async throws -> [String: Decimal] {
        return try await infoService.getAllMids()
    }
    
    /// Get L2 order book for a specific asset
    public func getL2Book(coin: String) async throws -> L2BookData {
        return try await infoService.getL2Book(coin: coin)
    }
    
    /// Get metadata for all assets
    public func getMeta() async throws -> Meta {
        return try await infoService.getMeta()
    }
    
    /// Get spot metadata
    public func getSpotMeta() async throws -> SpotMeta {
        return try await infoService.getSpotMeta()
    }
    
    // MARK: - Account Information Methods
    
    /// Get user state for the authenticated user
    public func getUserState() async throws -> UserState {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await infoService.getUserState(address: address)
    }
    
    /// Get user state for a specific address
    public func getUserState(address: String) async throws -> UserState {
        return try await infoService.getUserState(address: address)
    }
    
    /// Get open orders for the authenticated user
    public func getOpenOrders() async throws -> [OpenOrder] {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await infoService.getOpenOrders(address: address)
    }
    
    /// Get open orders for a specific address
    public func getOpenOrders(address: String) async throws -> [OpenOrder] {
        return try await infoService.getOpenOrders(address: address)
    }
    
    /// Get user fills for the authenticated user
    public func getUserFills() async throws -> [Fill] {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await infoService.getUserFills(address: address)
    }
    
    /// Get user fills for a specific address
    public func getUserFills(address: String) async throws -> [Fill] {
        return try await infoService.getUserFills(address: address)
    }
    
    // MARK: - Query Methods
    
    /// Query order by order ID
    public func queryOrderByOid(oid: OrderID) async throws -> OrderStatus? {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await infoService.queryOrderByOid(address: address, oid: oid)
    }
    
    /// Query order by client order ID
    public func queryOrderByCloid(cloid: ClientOrderID) async throws -> OrderStatus? {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await infoService.queryOrderByCloid(address: address, cloid: cloid)
    }
    
    /// Query referral state
    public func queryReferralState() async throws -> ReferralState {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await infoService.queryReferralState(address: address)
    }
    
    /// Query sub accounts
    public func querySubAccounts() async throws -> [SubAccount] {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await infoService.querySubAccounts(address: address)
    }
    
    // MARK: - Convenience Methods
    
    /// Get account summary with positions and balances
    public func getAccountSummary() async throws -> AccountSummary {
        let userState = try await getUserState()
        let openOrders = try await getOpenOrders()
        
        return AccountSummary(
            userState: userState,
            openOrders: openOrders,
            walletAddress: walletAddress ?? ""
        )
    }
    
    /// Check if client is authenticated
    public var isAuthenticated: Bool {
        return privateKey != nil
    }
}

// MARK: - Supporting Types

/// Account summary combining user state and open orders
public struct AccountSummary: Sendable {
    public let userState: UserState
    public let openOrders: [OpenOrder]
    public let walletAddress: String
    
    /// Total account value
    public var accountValue: Decimal {
        return userState.crossMarginSummary.accountValue
    }
    
    /// Total unrealized PnL
    public var totalUnrealizedPnl: Decimal {
        return userState.assetPositions.reduce(0) { $0 + $1.unrealizedPnl }
    }
    
    /// Number of open positions
    public var openPositionsCount: Int {
        return userState.assetPositions.filter { $0.szi != 0 }.count
    }
    
    /// Number of open orders
    public var openOrdersCount: Int {
        return openOrders.count
    }
    
    public init(userState: UserState, openOrders: [OpenOrder], walletAddress: String) {
        self.userState = userState
        self.openOrders = openOrders
        self.walletAddress = walletAddress
    }
}
