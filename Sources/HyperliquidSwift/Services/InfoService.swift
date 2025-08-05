import Foundation

/// Service for retrieving market data and account information
public actor InfoService: HTTPService {
    
    // MARK: - Properties
    
    public let environment: HyperliquidEnvironment
    public let httpClient: HTTPClient
    
    // MARK: - Initialization
    
    public init(environment: HyperliquidEnvironment) throws {
        self.environment = environment
        
        let config = HTTPClient.Configuration(baseURL: environment.apiURL)
        self.httpClient = try HTTPClient(configuration: config)
    }
    
    // MARK: - Market Data Methods
    
    /// Get all mid prices
    public func getAllMids() async throws -> [String: Decimal] {
        let payload = ["type": "allMids"]
        
        let response = try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: [String: String].self
        )
        
        // Convert string values to Decimal
        var result: [String: Decimal] = [:]
        for (key, value) in response {
            if let decimal = Decimal(string: value) {
                result[key] = decimal
            }
        }
        
        return result
    }
    
    /// Get L2 order book for a specific asset
    public func getL2Book(coin: String) async throws -> L2BookData {
        let payload = [
            "type": "l2Book",
            "coin": coin
        ]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: L2BookData.self
        )
    }
    
    /// Get metadata for all assets
    public func getMeta() async throws -> Meta {
        let payload = ["type": "meta"]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: Meta.self
        )
    }
    
    /// Get spot metadata
    public func getSpotMeta() async throws -> SpotMeta {
        let payload = ["type": "spotMeta"]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: SpotMeta.self
        )
    }
    
    // MARK: - Account Information Methods
    
    /// Get user state for a specific address
    public func getUserState(address: String) async throws -> UserState {
        let payload = [
            "type": "clearinghouseState",
            "user": address
        ]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: UserState.self
        )
    }
    
    /// Get open orders for a user
    public func getOpenOrders(address: String) async throws -> [OpenOrder] {
        let payload = [
            "type": "openOrders",
            "user": address
        ]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: [OpenOrder].self
        )
    }
    
    /// Get user fills
    public func getUserFills(address: String) async throws -> [Fill] {
        let payload = [
            "type": "userFills",
            "user": address
        ]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: [Fill].self
        )
    }
    
    // MARK: - Query Methods
    
    /// Query order by order ID
    public func queryOrderByOid(address: String, oid: OrderID) async throws -> OrderStatus? {
        let payload = [
            "type": "orderStatus",
            "user": address,
            "oid": oid
        ] as [String: Any]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: OrderStatus?.self
        )
    }
    
    /// Query order by client order ID
    public func queryOrderByCloid(address: String, cloid: ClientOrderID) async throws -> OrderStatus? {
        let payload = [
            "type": "orderStatus",
            "user": address,
            "cloid": cloid
        ]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: OrderStatus?.self
        )
    }
    
    /// Query referral state
    public func queryReferralState(address: String) async throws -> ReferralState {
        let payload = [
            "type": "referralState",
            "user": address
        ]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: ReferralState.self
        )
    }
    
    /// Query sub accounts
    public func querySubAccounts(address: String) async throws -> [SubAccount] {
        let payload = [
            "type": "subAccounts",
            "user": address
        ]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: [SubAccount].self
        )
    }
}

// MARK: - Supporting Types

/// User state information
public struct UserState: Codable, Sendable {
    public let assetPositions: [Position]
    public let crossMarginSummary: CrossMarginSummary
    public let crossMaintenanceMarginUsed: Decimal
    public let time: Int64
    
    public init(
        assetPositions: [Position],
        crossMarginSummary: CrossMarginSummary,
        crossMaintenanceMarginUsed: Decimal,
        time: Int64
    ) {
        self.assetPositions = assetPositions
        self.crossMarginSummary = crossMarginSummary
        self.crossMaintenanceMarginUsed = crossMaintenanceMarginUsed
        self.time = time
    }
}

/// Cross margin summary
public struct CrossMarginSummary: Codable, Sendable {
    public let accountValue: Decimal
    public let totalNtlPos: Decimal
    public let totalRawUsd: Decimal
    public let totalMarginUsed: Decimal
    
    public init(
        accountValue: Decimal,
        totalNtlPos: Decimal,
        totalRawUsd: Decimal,
        totalMarginUsed: Decimal
    ) {
        self.accountValue = accountValue
        self.totalNtlPos = totalNtlPos
        self.totalRawUsd = totalRawUsd
        self.totalMarginUsed = totalMarginUsed
    }
}

/// Referral state information
public struct ReferralState: Codable, Sendable {
    public let state: String
    public let code: String?
    
    public init(state: String, code: String? = nil) {
        self.state = state
        self.code = code
    }
}

/// Sub account information
public struct SubAccount: Codable, Sendable {
    public let subAccountUser: String
    public let clearinghouseState: UserState
    
    public init(subAccountUser: String, clearinghouseState: UserState) {
        self.subAccountUser = subAccountUser
        self.clearinghouseState = clearinghouseState
    }
}
