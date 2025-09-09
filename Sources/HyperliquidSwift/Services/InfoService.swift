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

    // For testing purposes - allows injection of mock HTTP client
    internal init(environment: HyperliquidEnvironment, httpClient: HTTPClient) {
        self.environment = environment
        self.httpClient = httpClient
    }
    
    // MARK: - Market Data Methods
    
    /// Get all mid prices
    public func getAllMids(dex: String = "") async throws -> [String: Decimal] {
        let payload = [
            "type": "allMids",
            "dex": dex
        ]

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
    public func getL2Book(coin: String) async throws -> JSONResponse {
        let payload = [
            "type": "l2Book",
            "coin": coin
        ]
        
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
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

    /// Get metadata and asset contexts
    public func getMetaAndAssetCtxs() async throws -> JSONResponse {
        let payload = [
            "type": "metaAndAssetCtxs"
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    /// Get spot metadata and asset contexts
    public func getSpotMetaAndAssetCtxs() async throws -> JSONResponse {
        let payload = [
            "type": "spotMetaAndAssetCtxs"
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }
    
    // MARK: - Account Information Methods
    
    /// Get user state for a specific address
    public func getUserState(address: String, dex: String = "") async throws -> UserState {
        let payload = [
            "type": "clearinghouseState",
            "user": address,
            "dex": dex
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: UserState.self
        )
    }
    
    /// Get open orders for a user
    public func getOpenOrders(address: String, dex: String = "") async throws -> [OpenOrder] {
        let payload = [
            "type": "openOrders",
            "user": address,
            "dex": dex
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: [OpenOrder].self
        )
    }

    /// Get frontend open orders for a user (with additional frontend info)
    public func getFrontendOpenOrders(address: String, dex: String = "") async throws -> JSONResponse {
        let payload = [
            "type": "frontendOpenOrders",
            "user": address,
            "dex": dex
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
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
            "type": "referral",
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

    // MARK: - Extended Info API Methods

    /// Get user fills by time range
    public func getUserFillsByTime(user: String, startTime: Int, endTime: Int? = nil) async throws -> [Fill] {
        var payload: [String: Any] = [
            "type": "userFillsByTime",
            "user": user,
            "startTime": startTime
        ]

        if let endTime = endTime {
            payload["endTime"] = endTime
        }

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: [Fill].self
        )
    }

    /// Get spot user state
    public func getSpotUserState(user: String) async throws -> JSONResponse {
        let payload = [
            "type": "spotClearinghouseState",
            "user": user
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    /// Get frontend open orders with additional info
    public func getFrontendOpenOrders(user: String, dex: String = "") async throws -> JSONResponse {
        let payload = [
            "type": "frontendOpenOrders",
            "user": user,
            "dex": dex
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    /// Get user fee information
    public func getUserFees(user: String) async throws -> JSONResponse {
        let payload = [
            "type": "userFees",
            "user": user
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    /// Get spot market metadata (raw JSON)
    public func getSpotMetaRaw() async throws -> JSONResponse {
        let payload = [
            "type": "spotMeta"
        ]

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Order Query Methods

    func queryOrderByOid(user: String, oid: UInt64) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "orderStatus", "user": user, "oid": oid],
            responseType: JSONResponse.self
        )
    }

    func queryOrderByCloid(user: String, cloid: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "orderStatus", "user": user, "oid": cloid],
            responseType: JSONResponse.self
        )
    }



    func getCandlesSnapshot(coin: String, interval: String, startTime: Int64, endTime: Int64) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: [
                "type": "candleSnapshot",
                "req": [
                    "coin": coin,
                    "interval": interval,
                    "startTime": startTime,
                    "endTime": endTime
                ]
            ],
            responseType: JSONResponse.self
        )
    }

    func getUserFillsByTime(address: String, startTime: Int64, endTime: Int64? = nil) async throws -> JSONResponse {
        var payload: [String: Any] = [
            "type": "userFillsByTime",
            "user": address,
            "startTime": startTime
        ]

        if let endTime = endTime {
            payload["endTime"] = endTime
        }

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    func getUserFundingHistory(user: String, startTime: Int64, endTime: Int64? = nil) async throws -> JSONResponse {
        var payload: [String: Any] = [
            "type": "userFundingHistory",
            "user": user,
            "startTime": startTime
        ]

        if let endTime = endTime {
            payload["endTime"] = endTime
        }

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    public func getUserFees(address: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "userFees", "user": address],
            responseType: JSONResponse.self
        )
    }

    public func getFrontendOpenOrders(address: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "frontendOpenOrders", "user": address],
            responseType: JSONResponse.self
        )
    }



    // MARK: - Staking Methods

    func getUserStakingSummary(address: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "userStakingSummary", "user": address],
            responseType: JSONResponse.self
        )
    }

    func getUserStakingDelegations(address: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "userStakingDelegations", "user": address],
            responseType: JSONResponse.self
        )
    }

    func getUserStakingRewards(address: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "userStakingRewards", "user": address],
            responseType: JSONResponse.self
        )
    }

    // MARK: - New Info API Parity Methods
    public func getPerpDexs() async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "perpDexs"],
            responseType: JSONResponse.self
        )
    }

    public func queryUserToMultiSigSigners(user: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "userToMultiSigSigners", "user": user],
            responseType: JSONResponse.self
        )
    }

    public func queryPerpDeployAuctionStatus() async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "perpDeployAuctionStatus"],
            responseType: JSONResponse.self
        )
    }

    // MARK: - Missing Methods for Feature Parity

    /// Get user funding payments history
    public func getUserFunding(user: String, startTime: Int, endTime: Int? = nil) async throws -> JSONResponse {
        var payload: [String: Any] = [
            "type": "userFunding",
            "user": user,
            "startTime": startTime
        ]

        if let endTime = endTime {
            payload["endTime"] = endTime
        }

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    /// Get funding rate history for a specific coin
    public func getFundingHistory(coin: String, startTime: Int, endTime: Int? = nil) async throws -> JSONResponse {
        var payload: [String: Any] = [
            "type": "fundingHistory",
            "coin": coin,
            "startTime": startTime
        ]

        if let endTime = endTime {
            payload["endTime"] = endTime
        }

        return try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: JSONResponse.self
        )
    }

    /// Query referral state for a user
    public func queryReferralState(user: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "referral", "user": user],
            responseType: JSONResponse.self
        )
    }

    /// Query sub accounts for a user
    public func querySubAccounts(user: String) async throws -> JSONResponse {
        return try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "subAccounts", "user": user],
            responseType: JSONResponse.self
        )
    }
}

// MARK: - Supporting Types

/// Asset position wrapper
public struct AssetPosition: Codable, Sendable {
    public let position: Position
    public let type: String

    public init(position: Position, type: String = "oneWay") {
        self.position = position
        self.type = type
    }
}

/// User state information
public struct UserState: Codable, Sendable {
    public let assetPositions: [AssetPosition]
    public let crossMarginSummary: CrossMarginSummary
    public let crossMaintenanceMarginUsed: Decimal
    public let time: Int64

    public init(
        assetPositions: [AssetPosition],
        crossMarginSummary: CrossMarginSummary,
        crossMaintenanceMarginUsed: Decimal,
        time: Int64
    ) {
        self.assetPositions = assetPositions
        self.crossMarginSummary = crossMarginSummary
        self.crossMaintenanceMarginUsed = crossMaintenanceMarginUsed
        self.time = time
    }

    // Custom decoding to handle String/Number values from API
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        assetPositions = try container.decode([AssetPosition].self, forKey: .assetPositions)
        crossMarginSummary = try container.decode(CrossMarginSummary.self, forKey: .crossMarginSummary)
        time = try container.decode(Int64.self, forKey: .time)

        // Handle crossMaintenanceMarginUsed as either String or Number
        if let marginUsedStr = try? container.decode(String.self, forKey: .crossMaintenanceMarginUsed) {
            guard let marginUsed = Decimal(string: marginUsedStr) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath + [CodingKeys.crossMaintenanceMarginUsed],
                        debugDescription: "Failed to convert string '\(marginUsedStr)' to Decimal"
                    )
                )
            }
            crossMaintenanceMarginUsed = marginUsed
        } else if let marginUsedDouble = try? container.decode(Double.self, forKey: .crossMaintenanceMarginUsed) {
            crossMaintenanceMarginUsed = Decimal(marginUsedDouble)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.crossMaintenanceMarginUsed],
                    debugDescription: "crossMaintenanceMarginUsed must be either String or Number"
                )
            )
        }
    }

    private enum CodingKeys: String, CodingKey {
        case assetPositions, crossMarginSummary, crossMaintenanceMarginUsed, time
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

    // Custom decoding to handle String values from API
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode string values and convert to Decimal
        let accountValueStr = try container.decode(String.self, forKey: .accountValue)
        let totalNtlPosStr = try container.decode(String.self, forKey: .totalNtlPos)
        let totalRawUsdStr = try container.decode(String.self, forKey: .totalRawUsd)
        let totalMarginUsedStr = try container.decode(String.self, forKey: .totalMarginUsed)

        guard let accountValue = Decimal(string: accountValueStr),
              let totalNtlPos = Decimal(string: totalNtlPosStr),
              let totalRawUsd = Decimal(string: totalRawUsdStr),
              let totalMarginUsed = Decimal(string: totalMarginUsedStr) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Failed to convert string values to Decimal"
                )
            )
        }

        self.accountValue = accountValue
        self.totalNtlPos = totalNtlPos
        self.totalRawUsd = totalRawUsd
        self.totalMarginUsed = totalMarginUsed
    }

    // Custom encoding to convert back to strings
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountValue.description, forKey: .accountValue)
        try container.encode(totalNtlPos.description, forKey: .totalNtlPos)
        try container.encode(totalRawUsd.description, forKey: .totalRawUsd)
        try container.encode(totalMarginUsed.description, forKey: .totalMarginUsed)
    }

    private enum CodingKeys: String, CodingKey {
        case accountValue, totalNtlPos, totalRawUsd, totalMarginUsed
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
