import Foundation

/// Main client for interacting with Hyperliquid API
public actor HyperliquidClient {

    // MARK: - Properties

    public let environment: HyperliquidEnvironment
    public let infoService: InfoService
    public let tradingService: TradingService?
    private let privateKey: HyperliquidSwift.PrivateKey?

    /// Wallet address (available when using authenticated client)
    public var walletAddress: String? {
        return privateKey?.walletAddress
    }

    // MARK: - Initialization

    /// Initialize read-only client (no trading capabilities)
    public init(environment: HyperliquidEnvironment = .mainnet) throws {
        self.environment = environment
        self.infoService = try InfoService(environment: environment)
        self.tradingService = nil
        self.privateKey = nil
    }

    /// Initialize authenticated client with trading capabilities
    public init(privateKeyHex: String, environment: HyperliquidEnvironment = .mainnet) throws {
        self.environment = environment
        self.infoService = try InfoService(environment: environment)
        self.privateKey = try PrivateKey(hex: privateKeyHex)

        // Initialize trading service for authenticated clients
        let config = HTTPClient.Configuration(baseURL: environment.apiURL)
        let httpClient = try HTTPClient(configuration: config)
        self.tradingService = TradingService(
            httpClient: httpClient,
            privateKey: self.privateKey!,
            environment: environment
        )
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

    /// Get metadata and asset contexts
    public func getMetaAndAssetCtxs() async throws -> JSONResponse {
        return try await infoService.getMetaAndAssetCtxs()
    }

    /// Get spot metadata and asset contexts
    public func getSpotMetaAndAssetCtxs() async throws -> JSONResponse {
        return try await infoService.getSpotMetaAndAssetCtxs()
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
    public func queryOrderByOid(oid: UInt64) async throws -> OrderStatus? {
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

    // MARK: - Extended Info API Methods

    /// Get user fills by time range
    public func getUserFillsByTime(user: String, startTime: Int, endTime: Int? = nil) async throws -> [Fill] {
        return try await infoService.getUserFillsByTime(user: user, startTime: startTime, endTime: endTime)
    }

    /// Get user fills by time range for authenticated user
    public func getUserFillsByTime(startTime: Int, endTime: Int? = nil) async throws -> [Fill] {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await getUserFillsByTime(user: address, startTime: startTime, endTime: endTime)
    }

    /// Get spot user state
    public func getSpotUserState(user: String) async throws -> [String: Any] {
        let response = try await infoService.getSpotUserState(user: user)
        return response.dictionary
    }

    /// Get spot user state for authenticated user
    public func getSpotUserState() async throws -> [String: Any] {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await getSpotUserState(user: address)
    }

    /// Get frontend open orders with additional info
    public func getFrontendOpenOrders(user: String, dex: String = "") async throws -> [String: Any] {
        let response = try await infoService.getFrontendOpenOrders(user: user, dex: dex)
        return response.dictionary
    }

    /// Get frontend open orders for authenticated user
    public func getFrontendOpenOrders(dex: String = "") async throws -> [String: Any] {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await getFrontendOpenOrders(user: address, dex: dex)
    }

    /// Get user fee information
    public func getUserFees(user: String) async throws -> [String: Any] {
        let response = try await infoService.getUserFees(user: user)
        return response.dictionary
    }

    /// Get user fee information for authenticated user
    public func getUserFees() async throws -> [String: Any] {
        guard let address = walletAddress else {
            throw HyperliquidError.authenticationRequired("Private key required for this operation")
        }
        return try await getUserFees(user: address)
    }

    /// Get spot market metadata (raw JSON)
    public func getSpotMetaRaw() async throws -> [String: Any] {
        let response = try await infoService.getSpotMetaRaw()
        return response.dictionary
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
        return userState.assetPositions.reduce(0) { $0 + $1.position.unrealizedPnl }
    }

    /// Number of open positions
    public var openPositionsCount: Int {
        return userState.assetPositions.filter { $0.position.szi != 0 }.count
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

// MARK: - Trading Methods Extension

extension HyperliquidClient {

    /// Place a limit buy order (BASIC VERSION - ONE METHOD ONLY)
    /// - Parameters:
    ///   - coin: Asset symbol (e.g., "BTC", "ETH")
    ///   - sz: Order size
    ///   - px: Limit price
    ///   - reduceOnly: Whether this is a reduce-only order
    /// - Returns: Order response
    public func limitBuy(
        coin: String,
        sz: Decimal,
        px: Decimal,
        reduceOnly: Bool = false
    ) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.authenticationRequired("Trading requires authenticated client")
        }

        return try await tradingService.limitBuy(coin: coin, sz: sz, px: px, reduceOnly: reduceOnly)
    }

    // MARK: - Order Placement

    /// Place a limit buy order
    /// - Parameters:
    ///   - coin: Asset symbol (e.g., "BTC", "ETH")
    ///   - sz: Order size
    ///   - px: Limit price
    ///   - reduceOnly: Whether this is a reduce-only order
    ///   - cloid: Client order ID (optional)
    /// - Returns: Order response
    public func limitBuy(
        coin: String,
        sz: Decimal,
        px: Decimal,
        reduceOnly: Bool = false,
        cloid: ClientOrderID? = nil
    ) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.authenticationRequired("Trading requires authenticated client")
        }
        return try await tradingService.limitBuy(coin: coin, sz: sz, px: px, reduceOnly: reduceOnly)
    }

    /// Place a limit sell order (STEP 2)
    /// - Parameters:
    ///   - coin: Asset symbol (e.g., "BTC", "ETH")
    ///   - sz: Order size
    ///   - px: Limit price
    ///   - reduceOnly: Whether this is a reduce-only order
    /// - Returns: Order response
    public func limitSell(
        coin: String,
        sz: Decimal,
        px: Decimal,
        reduceOnly: Bool = false
    ) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.authenticationRequired("Trading requires authenticated client")
        }

        return try await tradingService.limitSell(coin: coin, sz: sz, px: px, reduceOnly: reduceOnly)
    }

    // TODO: Implement market orders
    /// Place a market buy order
    public func marketBuy(coin: String, sz: Decimal, reduceOnly: Bool = false) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }

        return try await tradingService.marketOrder(
            coin: coin,
            isBuy: true,
            sz: sz,
            reduceOnly: reduceOnly
        )
    }

    /// Place a market sell order
    public func marketSell(coin: String, sz: Decimal, reduceOnly: Bool = false) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }

        return try await tradingService.marketOrder(
            coin: coin,
            isBuy: false,
            sz: sz,
            reduceOnly: reduceOnly
        )
    }

    /// Cancel a single order (STEP 3)
    /// - Parameters:
    ///   - coin: Asset symbol
    ///   - oid: Order ID to cancel
    /// - Returns: Cancel response
    public func cancelOrder(coin: String, oid: UInt64) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.authenticationRequired("Trading requires authenticated client")
        }

        return try await tradingService.cancelOrder(coin: coin, oid: oid)
    }

    /// Cancel all orders for a specific coin
    public func cancelAllOrders(coin: String) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }

        // Get all open orders for this coin
        let openOrders = try await getOpenOrders()
        let coinOrders = openOrders.filter { $0.coin == coin }

        guard !coinOrders.isEmpty else {
            // No orders to cancel - create empty success response
            return try await tradingService.createEmptyResponse()
        }

        // Cancel all orders for this coin
        return try await tradingService.cancelAllOrders(coin: coin, orders: coinOrders)
    }

    /// Cancel all orders across all coins
    public func cancelAllOrders() async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }

        // Get all open orders
        let openOrders = try await getOpenOrders()

        guard !openOrders.isEmpty else {
            // No orders to cancel - create empty success response
            return try await tradingService.createEmptyResponse()
        }

        // Group orders by coin and cancel all
        let ordersByCoin = Dictionary(grouping: openOrders, by: { $0.coin })

        // Cancel orders for each coin (could be optimized to batch cancel)
        var allResults: [[String: Any]] = []

        for (coin, orders) in ordersByCoin {
            let result = try await tradingService.cancelAllOrders(coin: coin, orders: orders)
            if let responseDict = result.dictionary["response"] as? [String: Any],
               let data = responseDict["data"] as? [String: Any],
               let statuses = data["statuses"] as? [[String: Any]] {
                allResults.append(contentsOf: statuses)
            }
        }

        // Return combined results
        return try await tradingService.createCombinedResponse(results: allResults)
    }

    /// Modify an existing order
    public func modifyOrder(oid: UInt64, coin: String, newPrice: Decimal, newSize: Decimal) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }

        return try await tradingService.modifyOrder(oid: oid, coin: coin, newPrice: newPrice, newSize: newSize)
    }

    /// Place multiple orders in a single request (bulk orders)
    public func bulkOrders(_ orders: [BulkOrderRequest]) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }

        return try await tradingService.bulkOrders(orders)
    }

    /// Query order status by order ID
    public func queryOrderByOid(user: String, oid: UInt64) async throws -> JSONResponse {
        return try await infoService.queryOrderByOid(user: user, oid: oid)
    }

    /// Query order status by client order ID
    public func queryOrderByCloid(user: String, cloid: String) async throws -> JSONResponse {
        return try await infoService.queryOrderByCloid(user: user, cloid: cloid)
    }

    /// Get funding history for a coin
    public func getFundingHistory(coin: String, startTime: Int64, endTime: Int64? = nil) async throws -> JSONResponse {
        return try await infoService.getFundingHistory(coin: coin, startTime: Int(startTime), endTime: endTime != nil ? Int(endTime!) : nil)
    }

    /// Get candles/OHLCV data for a coin
    public func getCandlesSnapshot(coin: String, interval: String, startTime: Int64, endTime: Int64) async throws -> JSONResponse {
        return try await infoService.getCandlesSnapshot(coin: coin, interval: interval, startTime: startTime, endTime: endTime)
    }

    /// Get user fills filtered by time
    public func getUserFillsByTime(address: String, startTime: Int64, endTime: Int64? = nil) async throws -> JSONResponse {
        return try await infoService.getUserFillsByTime(address: address, startTime: startTime, endTime: endTime)
    }

    /// Get user funding history
    public func getUserFundingHistory(user: String, startTime: Int64, endTime: Int64? = nil) async throws -> JSONResponse {
        return try await infoService.getUserFundingHistory(user: user, startTime: startTime, endTime: endTime)
    }

    /// Get user trading fees summary
    public func getUserFees(address: String) async throws -> JSONResponse {
        return try await infoService.getUserFees(address: address)
    }

    /// Get user funding history
    public func getUserFunding(user: String, startTime: Int, endTime: Int? = nil) async throws -> JSONResponse {
        return try await infoService.getUserFunding(user: user, startTime: startTime, endTime: endTime)
    }



    /// Get open orders with frontend information
    public func getFrontendOpenOrders(address: String) async throws -> JSONResponse {
        return try await infoService.getFrontendOpenOrders(address: address)
    }

    /// Query referral state for a user
    public func queryReferralState(user: String) async throws -> JSONResponse {
        return try await infoService.queryReferralState(user: user)
    }

    /// Query sub accounts for a user
    public func querySubAccounts(user: String) async throws -> JSONResponse {
        return try await infoService.querySubAccounts(user: user)
    }

    /// Get user staking summary
    public func getUserStakingSummary(address: String) async throws -> JSONResponse {
        return try await infoService.getUserStakingSummary(address: address)
    }

    /// Get user staking delegations
    public func getUserStakingDelegations(address: String) async throws -> JSONResponse {
        return try await infoService.getUserStakingDelegations(address: address)
    }

    /// Get user staking rewards history
    public func getUserStakingRewards(address: String) async throws -> JSONResponse {
        return try await infoService.getUserStakingRewards(address: address)
    }

    /// Cancel order by client order ID
    public func cancelOrderByCloid(coin: String, cloid: String) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }

        return try await tradingService.cancelOrderByCloid(coin: coin, cloid: cloid)
    }

    /// Schedule cancellation of all orders at a specific time
    public func scheduleCancel(time: Int64?) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }

        return try await tradingService.scheduleCancel(time: time)
    }
}


// MARK: - New parity methods
extension HyperliquidClient {
    public func bulkModifyOrders(_ modifies: [ModifyRequest]) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.bulkModifyOrders(modifies)
    }

    public func updateLeverage(coin: String, leverage: Int, isCross: Bool = true) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.updateLeverage(coin: coin, leverage: leverage, isCross: isCross)
    }

    public func updateIsolatedMargin(coin: String, amountUsd: Decimal, isBuy: Bool = true) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.updateIsolatedMargin(coin: coin, amountUsd: amountUsd, isBuy: isBuy)
    }

    public func setReferrer(code: String) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.setReferrer(code: code)
    }

    public func getPerpDexs() async throws -> JSONResponse {
        return try await infoService.getPerpDexs()
    }

    public func queryUserToMultiSigSigners(user: String) async throws -> JSONResponse {
        return try await infoService.queryUserToMultiSigSigners(user: user)
    }

    public func queryPerpDeployAuctionStatus() async throws -> JSONResponse {
        return try await infoService.queryPerpDeployAuctionStatus()
    }

    public func createSubAccount(name: String) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.createSubAccount(name: name)
    }

    // MARK: - Transfer Operations

    /// Transfer USDC between spot and perp wallets
    /// - Parameters:
    ///   - amount: Amount to transfer
    ///   - toPerp: true to transfer from spot to perp, false for perp to spot
    /// - Returns: Transfer response as JSONResponse
    public func usdClassTransfer(amount: Decimal, toPerp: Bool) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }
        return try await tradingService.usdClassTransfer(amount: amount, toPerp: toPerp)
    }

    /// Transfer USDC to another address
    /// - Parameters:
    ///   - amount: Amount to transfer
    ///   - destination: Destination address
    /// - Returns: Transfer response as JSONResponse
    public func usdTransfer(amount: Decimal, destination: String) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }
        return try await tradingService.usdTransfer(amount: amount, destination: destination)
    }

    /// Transfer spot tokens to another address
    /// - Parameters:
    ///   - amount: Amount to transfer
    ///   - destination: Destination address
    ///   - token: Token identifier (e.g., "PURR:0xc4bf3f870c0e9465323c0b6ed28096c2")
    /// - Returns: Transfer response as JSONResponse
    public func spotTransfer(amount: Decimal, destination: String, token: String) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }
        return try await tradingService.spotTransfer(amount: amount, destination: destination, token: token)
    }

    /// Transfer between main account and sub account
    /// - Parameters:
    ///   - subAccountUser: Sub account address
    ///   - isDeposit: true to deposit to sub account, false to withdraw
    ///   - usd: Amount in USD
    /// - Returns: Transfer response as JSONResponse
    public func subAccountTransfer(subAccountUser: String, isDeposit: Bool, usd: Decimal) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }
        return try await tradingService.subAccountTransfer(subAccountUser: subAccountUser, isDeposit: isDeposit, usd: usd)
    }

    /// Transfer USD to/from vault
    /// - Parameters:
    ///   - vaultAddress: Vault address
    ///   - isDeposit: true to deposit to vault, false to withdraw
    ///   - usd: Amount in USD (in micro-USD, e.g., 1000000 = $1)
    /// - Returns: Transfer response as JSONResponse
    public func vaultUsdTransfer(vaultAddress: String, isDeposit: Bool, usd: Int) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }
        return try await tradingService.vaultUsdTransfer(vaultAddress: vaultAddress, isDeposit: isDeposit, usd: usd)
    }

    /// Send asset between DEXs
    /// - Parameters:
    ///   - destination: Destination address
    ///   - sourceDex: Source DEX (empty string for default perp, "spot" for spot)
    ///   - destinationDex: Destination DEX
    ///   - token: Token identifier
    ///   - amount: Amount to transfer
    /// - Returns: Transfer response as JSONResponse
    public func sendAsset(destination: String, sourceDex: String, destinationDex: String, token: String, amount: Decimal) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }
        return try await tradingService.sendAsset(destination: destination, sourceDex: sourceDex, destinationDex: destinationDex, token: token, amount: amount)
    }

    /// Transfer spot tokens between main account and sub account
    /// - Parameters:
    ///   - subAccountUser: Sub account address
    ///   - isDeposit: true to deposit to sub account, false to withdraw
    ///   - token: Token identifier
    ///   - amount: Amount to transfer
    /// - Returns: Transfer response as JSONResponse
    public func subAccountSpotTransfer(subAccountUser: String, isDeposit: Bool, token: String, amount: Decimal) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }
        return try await tradingService.subAccountSpotTransfer(subAccountUser: subAccountUser, isDeposit: isDeposit, token: token, amount: amount)
    }

    /// Approve agent for automated trading
    /// - Parameters:
    ///   - agentAddress: Agent address to approve
    ///   - agentName: Name of the agent (optional)
    /// - Returns: Approval response as JSONResponse
    public func approveAgent(agentAddress: String, agentName: String? = nil) async throws -> JSONResponse {
        guard let tradingService = tradingService else {
            throw HyperliquidError.clientNotInitialized
        }
        return try await tradingService.approveAgent(agentAddress: agentAddress, agentName: agentName)
    }

    // MARK: - New Core Trading Methods

    /// Place a market buy order
    public func marketBuy(coin: String, sz: Decimal, slippage: Decimal = 0.05, reduceOnly: Bool = false) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.marketBuy(coin: coin, sz: sz, slippage: slippage, reduceOnly: reduceOnly)
    }

    /// Place a market sell order
    public func marketSell(coin: String, sz: Decimal, slippage: Decimal = 0.05, reduceOnly: Bool = false) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.marketSell(coin: coin, sz: sz, slippage: slippage, reduceOnly: reduceOnly)
    }



    // MARK: - Advanced Features

    /// Delegate tokens to validator
    public func tokenDelegate(validator: String, wei: Int, isUndelegate: Bool = false) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.tokenDelegate(validator: validator, wei: wei, isUndelegate: isUndelegate)
    }

    /// Withdraw from bridge
    public func withdrawFromBridge(amount: Decimal, destination: String) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.withdrawFromBridge(amount: amount, destination: destination)
    }

    /// Approve builder fee
    public func approveBuilderFee(builder: String, maxFeeRate: String) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.approveBuilderFee(builder: builder, maxFeeRate: maxFeeRate)
    }

    /// Convert account to multi-signature user
    public func convertToMultiSigUser(authorizedUsers: [String], threshold: Int) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.convertToMultiSigUser(authorizedUsers: authorizedUsers, threshold: threshold)
    }

    /// Execute multi-signature operation
    public func multiSig(
        multiSigUser: String,
        innerAction: [String: any Sendable],
        signatures: [String],
        nonce: Int64,
        vaultAddress: String? = nil
    ) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.multiSig(
            multiSigUser: multiSigUser,
            innerAction: innerAction,
            signatures: signatures,
            nonce: nonce,
            vaultAddress: vaultAddress
        )
    }

    /// Enable or disable big blocks
    public func useBigBlocks(enable: Bool) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.useBigBlocks(enable: enable)
    }

    /// Cancel multiple orders by client order ID
    public func bulkCancelByCloid(_ cancelRequests: [CancelByCloidRequest]) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.bulkCancelByCloid(cancelRequests)
    }

    /// Set expiration time for future orders
    public func setExpiresAfter(expiresAfter: Int64?) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.setExpiresAfter(expiresAfter: expiresAfter)
    }

    /// Place a stop loss order
    public func stopLossOrder(
        coin: String,
        isBuy: Bool,
        sz: Decimal,
        triggerPx: Decimal,
        limitPx: Decimal? = nil,
        isMarket: Bool = true,
        reduceOnly: Bool = true
    ) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.stopLossOrder(
            coin: coin,
            isBuy: isBuy,
            sz: sz,
            triggerPx: triggerPx,
            limitPx: limitPx,
            isMarket: isMarket,
            reduceOnly: reduceOnly
        )
    }

    /// Place a take profit order
    public func takeProfitOrder(
        coin: String,
        isBuy: Bool,
        sz: Decimal,
        triggerPx: Decimal,
        limitPx: Decimal? = nil,
        isMarket: Bool = true,
        reduceOnly: Bool = true
    ) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.takeProfitOrder(
            coin: coin,
            isBuy: isBuy,
            sz: sz,
            triggerPx: triggerPx,
            limitPx: limitPx,
            isMarket: isMarket,
            reduceOnly: reduceOnly
        )
    }

    /// Register as a validator
    public func registerValidator(
        nodeIp: String,
        name: String,
        description: String,
        discordUsername: String,
        commissionRate: String
    ) async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.registerValidator(
            nodeIp: nodeIp,
            name: name,
            description: description,
            discordUsername: discordUsername,
            commissionRate: commissionRate
        )
    }

    /// Unregister as a validator
    public func unregisterValidator() async throws -> JSONResponse {
        guard let tradingService = tradingService else { throw HyperliquidError.clientNotInitialized }
        return try await tradingService.unregisterValidator()
    }

}
