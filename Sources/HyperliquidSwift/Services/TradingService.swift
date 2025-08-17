import Foundation

/// Errors that can occur in TradingService
public enum TradingServiceError: Error {
    case invalidTransferType
    case signingFailed
    case invalidSignature
}

/// Service for handling trading operations
/// Designed to be Sendable and thread-safe for Swift 6 concurrency
public final class TradingService: Sendable {
    private let httpClient: HTTPClient
    private let privateKey: HyperliquidSwift.PrivateKey
    private let environment: HyperliquidEnvironment

    public init(httpClient: HTTPClient, privateKey: HyperliquidSwift.PrivateKey, environment: HyperliquidEnvironment) {
        self.httpClient = httpClient
        self.privateKey = privateKey
        self.environment = environment
    }

    // MARK: - Simple Order Methods (Start with one method only)

    /// Place a limit buy order
    /// - Parameters:
    ///   - coin: Asset symbol (e.g., "BTC", "ETH")
    ///   - sz: Order size
    ///   - px: Limit price
    ///   - reduceOnly: Whether this is a reduce-only order
    /// - Returns: Order response as JSONResponse
    public func limitBuy(
        coin: String,
        sz: Decimal,
        px: Decimal,
        reduceOnly: Bool = false
    ) async throws -> JSONResponse {
        // Create order data as Sendable dictionary
        let orderData: [String: any Sendable] = [
            "coin": coin,
            "is_buy": true,
            "sz": sz.description,
            "limit_px": px.description,
            "order_type": ["limit": ["tif": "Gtc"]],
            "reduce_only": reduceOnly
        ]

        return try await placeOrder(orderData: orderData)
    }

    /// Place a limit sell order
    /// - Parameters:
    ///   - coin: Asset symbol (e.g., "BTC", "ETH")
    ///   - sz: Order size
    ///   - px: Limit price
    ///   - reduceOnly: Whether this is a reduce-only order
    /// - Returns: Order response as JSONResponse
    public func limitSell(
        coin: String,
        sz: Decimal,
        px: Decimal,
        reduceOnly: Bool = false
    ) async throws -> JSONResponse {
        // Create order data as Sendable dictionary
        let orderData: [String: any Sendable] = [
            "coin": coin,
            "is_buy": false, // This is the key difference from limitBuy
            "sz": sz.description,
            "limit_px": px.description,
            "order_type": ["limit": ["tif": "Gtc"]],
            "reduce_only": reduceOnly
        ]

        return try await placeOrder(orderData: orderData)
    }

    /// Place a market buy order
    /// - Parameters:
    ///   - coin: Asset symbol (e.g., "BTC", "ETH")
    ///   - sz: Order size
    ///   - slippage: Maximum slippage tolerance (default 5%)
    ///   - reduceOnly: Whether this is a reduce-only order
    /// - Returns: Order response as JSONResponse
    public func marketBuy(
        coin: String,
        sz: Decimal,
        slippage: Decimal = 0.05,
        reduceOnly: Bool = false
    ) async throws -> JSONResponse {
        // Get current mid price and calculate slippage price
        let midPrice = try await getCurrentMidPrice(coin: coin)
        let slippagePrice = midPrice * (1 + slippage)

        let orderData: [String: any Sendable] = [
            "coin": coin,
            "is_buy": true,
            "sz": sz.description,
            "limit_px": slippagePrice.description,
            "order_type": ["limit": ["tif": "Ioc"]], // Immediate or Cancel for market orders
            "reduce_only": reduceOnly
        ]

        return try await placeOrder(orderData: orderData)
    }

    /// Place a market sell order
    /// - Parameters:
    ///   - coin: Asset symbol (e.g., "BTC", "ETH")
    ///   - sz: Order size
    ///   - slippage: Maximum slippage tolerance (default 5%)
    ///   - reduceOnly: Whether this is a reduce-only order
    /// - Returns: Order response as JSONResponse
    public func marketSell(
        coin: String,
        sz: Decimal,
        slippage: Decimal = 0.05,
        reduceOnly: Bool = false
    ) async throws -> JSONResponse {
        // Get current mid price and calculate slippage price
        let midPrice = try await getCurrentMidPrice(coin: coin)
        let slippagePrice = midPrice * (1 - slippage)

        let orderData: [String: any Sendable] = [
            "coin": coin,
            "is_buy": false,
            "sz": sz.description,
            "limit_px": slippagePrice.description,
            "order_type": ["limit": ["tif": "Ioc"]], // Immediate or Cancel for market orders
            "reduce_only": reduceOnly
        ]

        return try await placeOrder(orderData: orderData)
    }

    // MARK: - Helper Methods

    /// Get current mid price for a coin
    private func getCurrentMidPrice(coin: String) async throws -> Decimal {
        let payload = [
            "type": "allMids"
        ]

        let response = try await httpClient.postAndDecode(
            path: "/info",
            payload: payload,
            responseType: [String: String].self
        )

        guard let priceString = response[coin],
              let price = Decimal(string: priceString) else {
            throw HyperliquidError.responseParsingFailed("Could not get mid price for \(coin)")
        }

        return price
    }

    // MARK: - Order Management Methods

    /// Cancel an order
    /// - Parameters:
    ///   - coin: Asset symbol (e.g., "BTC", "ETH")
    ///   - oid: Order ID to cancel
    /// - Returns: Cancel response as JSONResponse
    public func cancelOrder(coin: String, oid: UInt64) async throws -> JSONResponse {
        // Convert coin to asset ID and create cancel data
        let assetId = try await getDynamicAssetId(for: coin)
        let cancelData: [String: any Sendable] = [
            "a": assetId,  // asset ID (not coin name)
            "o": oid       // order ID (shortened field name)
        ]

        return try await performCancel(cancelData: cancelData)
    }

    /// Place multiple orders in a single request
    /// - Parameter orders: Array of order requests
    /// - Returns: Bulk order response as JSONResponse
    public func bulkOrders(_ orders: [BulkOrderRequest]) async throws -> JSONResponse {
        var orderWires: [[String: any Sendable]] = []

        for order in orders {
            let assetId = try await getDynamicAssetId(for: order.coin)

            let orderWire: [String: any Sendable] = [
                "a": assetId,
                "b": order.isBuy,
                "p": order.px.description,
                "s": order.sz.description,
                "r": order.reduceOnly,
                "t": ["limit": ["tif": "Gtc"]]
            ]

            orderWires.append(orderWire)
        }

        let orderAction: [String: any Sendable] = [
            "type": "order",
            "orders": orderWires,
            "grouping": "na"
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: orderAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Cancel all orders for a specific coin
    /// - Parameter coin: Asset symbol to cancel orders for
    /// - Returns: Cancel response as JSONResponse
    public func cancelAllOrders(coin: String) async throws -> JSONResponse {
        let assetId = try await getDynamicAssetId(for: coin)

        let cancelAction: [String: any Sendable] = [
            "type": "cancel",
            "cancels": [["a": assetId, "o": "all"]]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: cancelAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Cancel all orders across all coins
    /// - Returns: Cancel response as JSONResponse
    public func cancelAllOrders() async throws -> JSONResponse {
        let cancelAction: [String: any Sendable] = [
            "type": "cancel",
            "cancels": [["a": "all", "o": "all"]]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: cancelAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Modify an existing order
    /// - Parameters:
    ///   - oid: Order ID to modify
    ///   - coin: Asset symbol
    ///   - newPrice: New limit price
    ///   - newSize: New order size
    /// - Returns: Modify response as JSONResponse
    public func modifyOrder(oid: UInt64, coin: String, newPrice: Decimal, newSize: Decimal) async throws -> JSONResponse {
        let assetId = try await getDynamicAssetId(for: coin)

        let orderWire: [String: any Sendable] = [
            "a": assetId,
            "b": true, // This will be determined by the existing order
            "p": newPrice.description,
            "s": newSize.description,
            "r": false,
            "t": ["limit": ["tif": "Gtc"]]
        ]

        let modifyWire: [String: any Sendable] = [
            "oid": oid,
            "order": orderWire
        ]

        let modifyAction: [String: any Sendable] = [
            "type": "batchModify",
            "modifies": [modifyWire]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: modifyAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Modify multiple orders in a single request
    /// - Parameter modifies: Array of modify requests
    /// - Returns: Bulk modify response as JSONResponse
    public func bulkModifyOrders(_ modifies: [ModifyRequest]) async throws -> JSONResponse {
        var modifyWires: [[String: any Sendable]] = []

        for modify in modifies {
            let assetId = try await getDynamicAssetId(for: modify.order.coin)

            let orderWire: [String: any Sendable] = [
                "a": assetId,
                "b": modify.order.isBuy,
                "p": modify.order.px.description,
                "s": modify.order.sz.description,
                "r": modify.order.reduceOnly,
                "t": ["limit": ["tif": "Gtc"]]
            ]

            var modifyWire: [String: any Sendable] = [
                "order": orderWire
            ]

            if let oid = modify.oid {
                modifyWire["oid"] = oid
            } else if let cloid = modify.cloid {
                modifyWire["cloid"] = cloid
            }

            modifyWires.append(modifyWire)
        }

        let modifyAction: [String: any Sendable] = [
            "type": "batchModify",
            "modifies": modifyWires
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: modifyAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Cancel order by client order ID
    /// - Parameters:
    ///   - coin: Asset symbol
    ///   - cloid: Client order ID
    /// - Returns: Cancel response as JSONResponse
    public func cancelOrderByCloid(coin: String, cloid: String) async throws -> JSONResponse {
        let assetId = try await getDynamicAssetId(for: coin)

        let cancelData: [String: any Sendable] = [
            "a": assetId,
            "o": cloid
        ]

        let cancelAction: [String: any Sendable] = [
            "type": "cancel",
            "cancels": [cancelData]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: cancelAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Schedule cancellation of all orders at a specific time
    /// - Parameter time: Timestamp in milliseconds (nil for immediate cancel)
    /// - Returns: Schedule cancel response as JSONResponse
    public func scheduleCancel(time: Int64?) async throws -> JSONResponse {
        let scheduleAction: [String: any Sendable] = [
            "type": "scheduleCancel",
            "time": time as Any
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: scheduleAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Account Management Methods

    /// Update leverage for a specific asset
    /// - Parameters:
    ///   - coin: Asset symbol
    ///   - leverage: New leverage value
    ///   - isCross: Whether to use cross margin (default: true)
    /// - Returns: Update leverage response as JSONResponse
    public func updateLeverage(coin: String, leverage: Int, isCross: Bool = true) async throws -> JSONResponse {
        let assetId = try await getDynamicAssetId(for: coin)

        let leverageAction: [String: any Sendable] = [
            "type": "updateLeverage",
            "asset": assetId,
            "isCross": isCross,
            "leverage": leverage
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: leverageAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Update isolated margin for a specific asset
    /// - Parameters:
    ///   - coin: Asset symbol
    ///   - amountUsd: Amount in USD to add/remove from isolated margin
    ///   - isBuy: Whether this is for a buy position (default: true)
    /// - Returns: Update isolated margin response as JSONResponse
    public func updateIsolatedMargin(coin: String, amountUsd: Decimal, isBuy: Bool = true) async throws -> JSONResponse {
        let assetId = try await getDynamicAssetId(for: coin)

        let marginAction: [String: any Sendable] = [
            "type": "updateIsolatedMargin",
            "asset": assetId,
            "isBuy": isBuy,
            "ntli": NSDecimalNumber(decimal: amountUsd * 1000000).intValue // Convert to micro-USD
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: marginAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Set referrer code
    /// - Parameter code: Referrer code
    /// - Returns: Set referrer response as JSONResponse
    public func setReferrer(code: String) async throws -> JSONResponse {
        let referrerAction: [String: any Sendable] = [
            "type": "setReferrer",
            "code": code
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: referrerAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Create a sub-account
    /// - Parameter name: Name for the sub-account
    /// - Returns: Create sub-account response as JSONResponse
    public func createSubAccount(name: String) async throws -> JSONResponse {
        let subAccountAction: [String: any Sendable] = [
            "type": "createSubAccount",
            "name": name
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: subAccountAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Advanced Features

    /// Delegate tokens to a validator
    /// - Parameters:
    ///   - validator: Validator address
    ///   - wei: Amount in wei to delegate
    ///   - isUndelegate: Whether this is an undelegation (default: false)
    /// - Returns: Token delegate response as JSONResponse
    public func tokenDelegate(validator: String, wei: Int, isUndelegate: Bool = false) async throws -> JSONResponse {
        let delegateAction: [String: any Sendable] = [
            "type": "tokenDelegate",
            "validator": validator,
            "wei": wei,
            "isUndelegate": isUndelegate
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createUserSignedRequest(action: delegateAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Withdraw from bridge
    /// - Parameters:
    ///   - amount: Amount to withdraw
    ///   - destination: Destination address
    /// - Returns: Withdraw response as JSONResponse
    public func withdrawFromBridge(amount: Decimal, destination: String) async throws -> JSONResponse {
        let withdrawAction: [String: any Sendable] = [
            "type": "withdrawFromBridge",
            "amount": amount.description,
            "destination": destination
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createUserSignedRequest(action: withdrawAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Approve builder fee
    /// - Parameters:
    ///   - builder: Builder address
    ///   - maxFeeRate: Maximum fee rate
    /// - Returns: Approve builder fee response as JSONResponse
    public func approveBuilderFee(builder: String, maxFeeRate: String) async throws -> JSONResponse {
        let approveAction: [String: any Sendable] = [
            "type": "approveBuilderFee",
            "builder": builder,
            "maxFeeRate": maxFeeRate
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: approveAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Convert account to multi-signature user
    /// - Parameters:
    ///   - authorizedUsers: Array of authorized user addresses
    ///   - threshold: Number of signatures required
    /// - Returns: Convert to multi-sig response as JSONResponse
    public func convertToMultiSigUser(authorizedUsers: [String], threshold: Int) async throws -> JSONResponse {
        let convertAction: [String: any Sendable] = [
            "type": "convertToMultiSigUser",
            "authorizedUsers": authorizedUsers,
            "threshold": threshold
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: convertAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Execute multi-signature operation
    /// - Parameters:
    ///   - multiSigUser: Multi-sig user address
    ///   - innerAction: The action to execute
    ///   - signatures: Array of signatures
    ///   - nonce: Nonce for the operation
    ///   - vaultAddress: Optional vault address
    /// - Returns: Multi-sig operation response as JSONResponse
    public func multiSig(
        multiSigUser: String,
        innerAction: [String: any Sendable],
        signatures: [String],
        nonce: Int64,
        vaultAddress: String? = nil
    ) async throws -> JSONResponse {
        let multiSigAction: [String: any Sendable] = [
            "type": "multiSig",
            "multiSigUser": multiSigUser.lowercased(),
            "innerAction": innerAction,
            "signatures": signatures,
            "nonce": nonce,
            "vaultAddress": vaultAddress as Any
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: multiSigAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Enable or disable big blocks
    /// - Parameter enable: Whether to enable big blocks
    /// - Returns: Use big blocks response as JSONResponse
    public func useBigBlocks(enable: Bool) async throws -> JSONResponse {
        let bigBlocksAction: [String: any Sendable] = [
            "type": "useBigBlocks",
            "enable": enable
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: bigBlocksAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Cancel multiple orders by client order ID
    /// - Parameter cancelRequests: Array of cancel requests with coin and cloid
    /// - Returns: Bulk cancel response as JSONResponse
    public func bulkCancelByCloid(_ cancelRequests: [CancelByCloidRequest]) async throws -> JSONResponse {
        var cancelWires: [[String: any Sendable]] = []

        for request in cancelRequests {
            let assetId = try await getDynamicAssetId(for: request.coin)

            let cancelWire: [String: any Sendable] = [
                "a": assetId,
                "o": request.cloid
            ]

            cancelWires.append(cancelWire)
        }

        let cancelAction: [String: any Sendable] = [
            "type": "cancel",
            "cancels": cancelWires
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: cancelAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Set expiration time for future orders
    /// - Parameter expiresAfter: Timestamp in milliseconds after which orders will be rejected (nil to disable)
    /// - Returns: Set expires after response as JSONResponse
    public func setExpiresAfter(expiresAfter: Int64?) async throws -> JSONResponse {
        let expiresAction: [String: any Sendable] = [
            "type": "setExpiresAfter",
            "expiresAfter": expiresAfter as Any
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: expiresAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Advanced Order Types (TPSL)

    /// Place a stop loss order
    /// - Parameters:
    ///   - coin: Asset symbol
    ///   - isBuy: Whether this is a buy order
    ///   - sz: Order size
    ///   - triggerPx: Trigger price for the stop loss
    ///   - limitPx: Limit price (use triggerPx for market stop loss)
    ///   - isMarket: Whether this is a market stop loss (default: true)
    ///   - reduceOnly: Whether this is reduce-only (default: true for stop loss)
    /// - Returns: Stop loss order response as JSONResponse
    public func stopLossOrder(
        coin: String,
        isBuy: Bool,
        sz: Decimal,
        triggerPx: Decimal,
        limitPx: Decimal? = nil,
        isMarket: Bool = true,
        reduceOnly: Bool = true
    ) async throws -> JSONResponse {
        let orderType: [String: any Sendable] = [
            "trigger": [
                "triggerPx": triggerPx.description,
                "isMarket": isMarket,
                "tpsl": "sl"
            ]
        ]

        let orderData: [String: any Sendable] = [
            "coin": coin,
            "is_buy": isBuy,
            "sz": sz.description,
            "limit_px": (limitPx ?? triggerPx).description,
            "order_type": orderType,
            "reduce_only": reduceOnly
        ]

        return try await placeOrder(orderData: orderData)
    }

    /// Place a take profit order
    /// - Parameters:
    ///   - coin: Asset symbol
    ///   - isBuy: Whether this is a buy order
    ///   - sz: Order size
    ///   - triggerPx: Trigger price for the take profit
    ///   - limitPx: Limit price (use triggerPx for market take profit)
    ///   - isMarket: Whether this is a market take profit (default: true)
    ///   - reduceOnly: Whether this is reduce-only (default: true for take profit)
    /// - Returns: Take profit order response as JSONResponse
    public func takeProfitOrder(
        coin: String,
        isBuy: Bool,
        sz: Decimal,
        triggerPx: Decimal,
        limitPx: Decimal? = nil,
        isMarket: Bool = true,
        reduceOnly: Bool = true
    ) async throws -> JSONResponse {
        let orderType: [String: any Sendable] = [
            "trigger": [
                "triggerPx": triggerPx.description,
                "isMarket": isMarket,
                "tpsl": "tp"
            ]
        ]

        let orderData: [String: any Sendable] = [
            "coin": coin,
            "is_buy": isBuy,
            "sz": sz.description,
            "limit_px": (limitPx ?? triggerPx).description,
            "order_type": orderType,
            "reduce_only": reduceOnly
        ]

        return try await placeOrder(orderData: orderData)
    }

    // MARK: - Validator Operations

    /// Register as a validator
    /// - Parameters:
    ///   - nodeIp: IP address of the validator node
    ///   - name: Name of the validator
    ///   - description: Description of the validator
    ///   - discordUsername: Discord username for contact
    ///   - commissionRate: Commission rate (e.g., "0.05" for 5%)
    /// - Returns: Validator registration response as JSONResponse
    public func registerValidator(
        nodeIp: String,
        name: String,
        description: String,
        discordUsername: String,
        commissionRate: String
    ) async throws -> JSONResponse {
        let validatorAction: [String: any Sendable] = [
            "type": "CValidatorAction",
            "cValidatorAction": [
                "register": [
                    "nodeIp": nodeIp,
                    "name": name,
                    "description": description,
                    "discordUsername": discordUsername,
                    "commissionRate": commissionRate
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: validatorAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Unregister as a validator
    /// - Returns: Validator unregistration response as JSONResponse
    public func unregisterValidator() async throws -> JSONResponse {
        let validatorAction: [String: any Sendable] = [
            "type": "CValidatorAction",
            "cValidatorAction": [
                "unregister": [:] as [String: String]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: validatorAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Change validator profile
    /// - Parameters:
    ///   - nodeIp: New IP address (nil to keep current)
    ///   - name: New name (nil to keep current)
    ///   - description: New description (nil to keep current)
    ///   - discordUsername: New Discord username (nil to keep current)
    ///   - commissionRate: New commission rate (nil to keep current)
    /// - Returns: Validator profile change response as JSONResponse
    public func changeValidatorProfile(
        nodeIp: String? = nil,
        name: String? = nil,
        description: String? = nil,
        discordUsername: String? = nil,
        commissionRate: String? = nil
    ) async throws -> JSONResponse {
        var changeProfile: [String: any Sendable] = [:]

        if let nodeIp = nodeIp { changeProfile["nodeIp"] = nodeIp }
        if let name = name { changeProfile["name"] = name }
        if let description = description { changeProfile["description"] = description }
        if let discordUsername = discordUsername { changeProfile["discordUsername"] = discordUsername }
        if let commissionRate = commissionRate { changeProfile["commissionRate"] = commissionRate }

        let validatorAction: [String: any Sendable] = [
            "type": "CValidatorAction",
            "cValidatorAction": [
                "changeProfile": changeProfile
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: validatorAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - C-Signer Operations

    /// Unjail self as a signer
    /// - Returns: Unjail response as JSONResponse
    public func cSignerUnjailSelf() async throws -> JSONResponse {
        return try await cSignerInner(variant: "unjailSelf")
    }

    /// Jail self as a signer
    /// - Returns: Jail response as JSONResponse
    public func cSignerJailSelf() async throws -> JSONResponse {
        return try await cSignerInner(variant: "jailSelf")
    }

    /// Internal method for C-Signer operations
    /// - Parameter variant: The signer operation variant
    /// - Returns: Signer operation response as JSONResponse
    private func cSignerInner(variant: String) async throws -> JSONResponse {
        let signerAction: [String: any Sendable] = [
            "type": "CSignerAction",
            "cSignerAction": [
                variant: [:] as [String: String]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: signerAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Spot Deployment Operations

    /// Register a new spot token
    /// - Parameters:
    ///   - tokenName: Name of the token
    ///   - szDecimals: Size decimals for the token
    ///   - weiDecimals: Wei decimals for the token
    ///   - maxGas: Maximum gas for operations
    ///   - fullName: Full name of the token
    /// - Returns: Spot token registration response as JSONResponse
    public func spotDeployRegisterToken(
        tokenName: String,
        szDecimals: Int,
        weiDecimals: Int,
        maxGas: Int,
        fullName: String
    ) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "registerToken": [
                    "name": tokenName,
                    "szDecimals": szDecimals,
                    "weiDecimals": weiDecimals,
                    "maxGas": maxGas,
                    "fullName": fullName
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Perpetual Deployment Operations

    /// Register a new perpetual asset
    /// - Parameters:
    ///   - dex: DEX identifier
    ///   - name: Asset name
    ///   - szDecimals: Size decimals
    ///   - maxLeverage: Maximum leverage allowed
    ///   - onlyIsolated: Whether only isolated margin is allowed
    /// - Returns: Perpetual asset registration response as JSONResponse
    public func perpDeployRegisterAsset(
        dex: String,
        name: String,
        szDecimals: Int,
        maxLeverage: Int,
        onlyIsolated: Bool
    ) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "perpDeploy",
            "perpDeploy": [
                "registerAsset": [
                    "dex": dex,
                    "name": name,
                    "szDecimals": szDecimals,
                    "maxLeverage": maxLeverage,
                    "onlyIsolated": onlyIsolated
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Agent Operations

    /// Approve an agent wallet
    /// - Parameter agentName: Optional name for the agent
    /// - Returns: Tuple containing the approval response and the agent private key
    public func approveAgent(agentName: String? = nil) async throws -> (response: JSONResponse, agentKey: String) {
        // Generate a new private key for the agent (32 random bytes as hex)
        let agentKey = generateRandomPrivateKey()
        let agentPrivateKey = try PrivateKey(hex: agentKey)
        let agentAddress = agentPrivateKey.walletAddress

        let approveAction: [String: any Sendable] = [
            "type": "approveAgent",
            "agentAddress": agentAddress,
            "agentName": agentName as Any
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: approveAction, timestamp: timestamp)

        let response = try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )

        return (response: response, agentKey: agentKey)
    }

    /// Generate a random private key
    /// - Returns: 32-byte private key as hex string
    private func generateRandomPrivateKey() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            // Fallback to a deterministic but random-looking key
            return "0x" + String(repeating: "0123456789abcdef", count: 4)
        }
        return "0x" + bytes.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Advanced Spot Deployment Operations

    /// Genesis deployment for spot token
    /// - Parameters:
    ///   - token: Token ID
    ///   - maxSupply: Maximum supply as string
    ///   - noHyperliquidity: Whether to disable hyperliquidity
    /// - Returns: Spot genesis deployment response as JSONResponse
    public func spotDeployGenesis(
        token: Int,
        maxSupply: String,
        noHyperliquidity: Bool
    ) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "genesis": [
                    "token": token,
                    "maxSupply": maxSupply,
                    "noHyperliquidity": noHyperliquidity
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Register a spot trading pair
    /// - Parameters:
    ///   - baseToken: Base token ID
    ///   - quoteToken: Quote token ID
    /// - Returns: Spot pair registration response as JSONResponse
    public func spotDeployRegisterSpot(
        baseToken: Int,
        quoteToken: Int
    ) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "registerSpot": [
                    "baseToken": baseToken,
                    "quoteToken": quoteToken
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// User genesis for spot deployment
    /// - Parameters:
    ///   - token: Token ID
    ///   - userAndWei: Array of tuples containing user addresses and wei amounts
    ///   - existingTokenAndWei: Array of tuples containing existing token IDs and wei amounts
    /// - Returns: User genesis deployment response as JSONResponse
    public func spotDeployUserGenesis(
        token: Int,
        userAndWei: [(String, String)],
        existingTokenAndWei: [(Int, String)]
    ) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "userGenesis": [
                    "token": token,
                    "userAndWei": userAndWei.map { [$0.0, $0.1] },
                    "existingTokenAndWei": existingTokenAndWei.map { [$0.0, $0.1] }
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Advanced Perpetual Deployment Operations

    /// Set oracle for perpetual deployment
    /// - Parameters:
    ///   - dex: DEX identifier
    ///   - oraclePrices: Dictionary of oracle prices
    ///   - maxGas: Maximum gas for operations
    /// - Returns: Oracle set response as JSONResponse
    public func perpDeploySetOracle(
        dex: String,
        oraclePrices: [String: String],
        maxGas: Int? = nil
    ) async throws -> JSONResponse {
        var setOracle: [String: any Sendable] = [
            "dex": dex,
            "oraclePxs": oraclePrices
        ]

        if let maxGas = maxGas {
            setOracle["maxGas"] = maxGas
        }

        let deployAction: [String: any Sendable] = [
            "type": "perpDeploy",
            "perpDeploy": [
                "setOracle": setOracle
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Advanced Spot Freeze Operations

    /// Enable freeze privilege for a spot token
    /// - Parameter token: Token ID
    /// - Returns: Enable freeze privilege response as JSONResponse
    public func spotDeployEnableFreezePrivilege(token: Int) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "enableFreezePrivilege": [
                    "token": token
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Freeze or unfreeze a user for a spot token
    /// - Parameters:
    ///   - token: Token ID
    ///   - user: User address to freeze/unfreeze
    ///   - freeze: Whether to freeze (true) or unfreeze (false)
    /// - Returns: Freeze user response as JSONResponse
    public func spotDeployFreezeUser(
        token: Int,
        user: String,
        freeze: Bool
    ) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "freezeUser": [
                    "token": token,
                    "user": user,
                    "freeze": freeze
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Revoke freeze privilege for a spot token
    /// - Parameter token: Token ID
    /// - Returns: Revoke freeze privilege response as JSONResponse
    public func spotDeployRevokeFreezePrivilege(token: Int) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "revokeFreezePrivilege": [
                    "token": token
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Register hyperliquidity for a spot token
    /// - Parameters:
    ///   - spot: Spot ID
    ///   - startPx: Starting price
    ///   - orderSz: Order size
    ///   - nOrders: Number of orders
    ///   - nSeededLevels: Number of seeded levels (optional)
    /// - Returns: Register hyperliquidity response as JSONResponse
    public func spotDeployRegisterHyperliquidity(
        spot: Int,
        startPx: Double,
        orderSz: Double,
        nOrders: Int,
        nSeededLevels: Int? = nil
    ) async throws -> JSONResponse {
        var registerHyperliquidity: [String: any Sendable] = [
            "spot": spot,
            "startPx": startPx,
            "orderSz": orderSz,
            "nOrders": nOrders
        ]

        if let nSeededLevels = nSeededLevels {
            registerHyperliquidity["nSeededLevels"] = nSeededLevels
        }

        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "registerHyperliquidity": registerHyperliquidity
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    /// Set deployer trading fee share for a spot token
    /// - Parameters:
    ///   - token: Token ID
    ///   - share: Fee share as string (e.g., "0.1" for 10%)
    /// - Returns: Set deployer trading fee share response as JSONResponse
    public func spotDeploySetDeployerTradingFeeShare(
        token: Int,
        share: String
    ) async throws -> JSONResponse {
        let deployAction: [String: any Sendable] = [
            "type": "spotDeploy",
            "spotDeploy": [
                "setDeployerTradingFeeShare": [
                    "token": token,
                    "share": share
                ]
            ]
        ]

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: deployAction, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // MARK: - Private Implementation

    private func placeOrder(orderData: [String: any Sendable]) async throws -> JSONResponse {
        // Convert coin to asset ID (simplified mapping for now)
        let coin = orderData["coin"] as? String ?? ""
        let assetId = try await getDynamicAssetId(for: coin)

        // Create OrderWire structure
        let orderWire: [String: any Sendable] = [
            "a": assetId,                                    // asset ID
            "b": orderData["is_buy"] as? Bool ?? true,       // is_buy
            "p": orderData["limit_px"] as? String ?? "0",    // limit price
            "s": orderData["sz"] as? String ?? "0",          // size
            "r": orderData["reduce_only"] as? Bool ?? false, // reduce_only
            "t": orderData["order_type"] ?? ["limit": ["tif": "Gtc"]] // order type
        ]

        // Create order action with Sendable types
        let orderAction: [String: any Sendable] = [
            "type": "order",
            "orders": [orderWire],
            "grouping": "na"
        ]

        // Create signed request
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: orderAction, timestamp: timestamp)

        // Send to exchange
        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // Dynamic asset lookup
    private func getDynamicAssetId(for coin: String) async throws -> Int {
        // Get metadata from API using POST request
        let meta = try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "meta"],  // Use "meta" for perp assets (ETH, BTC, etc)
            responseType: JSONResponse.self
        )

        // Find asset by name in universe array
        if let universe = meta.dictionary["universe"] as? [[String: Any]] {
            for (index, asset) in universe.enumerated() {
                if let name = asset["name"] as? String,
                   name.uppercased() == coin.uppercased() {
                    return index
                }
            }
        }

        throw HyperliquidError.requestFailed(statusCode: 400, message: "Asset not found: \(coin)")
    }

    // Get asset ID for a coin name
    private func getAssetId(for coin: String) async throws -> Int {
        // Get metadata from API using POST request like
        let meta = try await httpClient.postAndDecode(
            path: "/info",
            payload: ["type": "meta"],  // Use "meta" for perp assets (ETH, BTC, etc)
            responseType: JSONResponse.self
        )

        // Parse the response to find asset ID
        guard let responseDict = meta.dictionary["universe"] as? [[String: Any]] else {
            throw HyperliquidError.requestFailed(statusCode: 400, message: "Invalid meta response format")
        }

        // Find the asset by name
        for (index, asset) in responseDict.enumerated() {
            if let name = asset["name"] as? String, name == coin {
                return index
            }
        }

        throw HyperliquidError.requestFailed(statusCode: 400, message: "Asset not found: \(coin)")
    }

    // float_to_wire() equivalent
    private func floatToWire(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.usesGroupingSeparator = false

        let formatted = formatter.string(from: nsDecimal) ?? "0"

        // Remove trailing zeros and decimal point if not needed
        if let decimal = Decimal(string: formatted) {
            let result = decimal.description
            // Remove .0 if it's a whole number
            if result.hasSuffix(".0") {
                return String(result.dropLast(2))
            }
            return result
        }

        return "0"
    }

    private func createSignedRequest(action: [String: any Sendable], timestamp: Int64) async throws -> [String: Any] {
        // Convert to JSONResponse for Codable compatibility
        let actionData = try JSONSerialization.data(withJSONObject: action)
        let jsonResponse = try JSONDecoder().decode(JSONResponse.self, from: actionData)

        // Use CryptoService for proper EIP-712 signing
        let signatureHex = try CryptoService.signL1Action(
            action: jsonResponse,
            privateKey: privateKey,
            vaultAddress: nil,
            timestamp: timestamp,
            isMainnet: environment == .mainnet
        )

        let signature = try convertSignatureToRSV(signatureHex)

        // Create request with proper null handling
        var request: [String: Any] = [
            "action": action,
            "nonce": timestamp,
            "signature": signature
        ]

        // Add null fields explicitly (some APIs require these fields to be present)
        request["vaultAddress"] = NSNull()
        request["expiresAfter"] = NSNull()

        return request
    }

    private func performCancel(cancelData: [String: any Sendable]) async throws -> JSONResponse {
        // Create cancel action with Sendable types
        let cancelAction: [String: any Sendable] = [
            "type": "cancel",
            "cancels": [cancelData]
        ]

        // Create signed request
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signedRequest = try await createSignedRequest(action: cancelAction, timestamp: timestamp)

        // Send to exchange
        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: signedRequest,
            responseType: JSONResponse.self
        )
    }

    // Cancel all orders for a specific coin
    func cancelAllOrders(coin: String, orders: [OpenOrder]) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // Create cancel requests for all orders
        var cancelRequests: [[String: any Sendable]] = []

        for order in orders {
            let assetId = try await getAssetId(for: order.coin)
            cancelRequests.append([
                "a": assetId,
                "o": order.oid
            ])
        }

        let action: [String: any Sendable] = [
            "type": "cancel",
            "cancels": cancelRequests
        ]

        let request = try await createSignedRequest(action: action, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }



    // Place a market order
    func marketOrder(coin: String, isBuy: Bool, sz: Decimal, reduceOnly: Bool) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // Get asset ID for the coin
        let assetId = try await getAssetId(for: coin)

        // Market orders use a special price and order type
        let orderWire: [String: any Sendable] = [
            "a": assetId,
            "b": isBuy,
            "p": "@0", // Special market order price
            "s": floatToWire(sz),
            "r": reduceOnly,
            "t": ["market": [:] as [String: any Sendable]] // Market order type
        ]

        let action: [String: any Sendable] = [
            "type": "order",
            "orders": [orderWire],
            "grouping": "na"
        ]

        let request = try await createSignedRequest(action: action, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }












    // Helper method to create empty success response
    func createEmptyResponse() async throws -> JSONResponse {
        let emptyResponse: [String: Any] = ["status": "ok", "response": ["type": "cancel", "data": ["statuses": []]]]
        let data = try JSONSerialization.data(withJSONObject: emptyResponse)
        let decoder = JSONDecoder()
        return try decoder.decode(JSONResponse.self, from: data)
    }

    // Helper method to create combined response
    func createCombinedResponse(results: [[String: Any]]) async throws -> JSONResponse {
        let combinedResponse = [
            "status": "ok",
            "response": [
                "type": "cancel",
                "data": ["statuses": results]
            ]
        ] as [String: Any]
        let data = try JSONSerialization.data(withJSONObject: combinedResponse)
        let decoder = JSONDecoder()
        return try decoder.decode(JSONResponse.self, from: data)
    }

    private func convertSignatureToRSV(_ signatureHex: String) throws -> [String: Any] {
        // Remove 0x prefix
        let hex = signatureHex.hasPrefix("0x") ? String(signatureHex.dropFirst(2)) : signatureHex

        // Signature should be 130 chars (65 bytes): 64 bytes (r+s) + 1 byte (v)
        guard hex.count == 130 else {
            throw HyperliquidError.requestFailed(statusCode: 400, message: "Invalid signature length")
        }

        // Extract r, s, v
        let r = "0x" + String(hex.prefix(64))
        let s = "0x" + String(hex.dropFirst(64).prefix(64))
        let vByte = UInt8(String(hex.suffix(2)), radix: 16) ?? 0

        // Convert recovery ID to v (27 or 28)
        let v = vByte >= 27 ? Int(vByte) : Int(vByte) + 27

        return [
            "r": r,
            "s": s,
            "v": v
        ]
    }

    // MARK: - Transfer Operations

    /// Transfer USDC between spot and perp wallets
    /// - Parameters:
    ///   - amount: Amount to transfer
    ///   - toPerp: true to transfer from spot to perp, false for perp to spot
    /// - Returns: Transfer response as JSONResponse
    public func usdClassTransfer(amount: Decimal, toPerp: Bool) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let action: [String: any Sendable] = [
            "type": "usdClassTransfer",
            "amount": amount.description,
            "toPerp": toPerp,
            "nonce": timestamp
        ]

        return try await executeTransferAction(action: action, timestamp: timestamp, isUserSigned: true)
    }

    /// Transfer USDC to another address
    /// - Parameters:
    ///   - amount: Amount to transfer
    ///   - destination: Destination address
    /// - Returns: Transfer response as JSONResponse
    public func usdTransfer(amount: Decimal, destination: String) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let action: [String: any Sendable] = [
            "type": "usdSend",
            "destination": destination,
            "amount": amount.description,
            "time": timestamp
        ]

        return try await executeTransferAction(action: action, timestamp: timestamp, isUserSigned: true)
    }

    /// Transfer spot tokens to another address
    /// - Parameters:
    ///   - amount: Amount to transfer
    ///   - destination: Destination address
    ///   - token: Token identifier (e.g., "PURR:0xc4bf3f870c0e9465323c0b6ed28096c2")
    /// - Returns: Transfer response as JSONResponse
    public func spotTransfer(amount: Decimal, destination: String, token: String) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let action: [String: any Sendable] = [
            "type": "spotSend",
            "destination": destination,
            "amount": amount.description,
            "token": token,
            "time": timestamp
        ]

        return try await executeTransferAction(action: action, timestamp: timestamp, isUserSigned: true)
    }

    /// Transfer between main account and sub account
    /// - Parameters:
    ///   - subAccountUser: Sub account address
    ///   - isDeposit: true to deposit to sub account, false to withdraw
    ///   - usd: Amount in USD
    /// - Returns: Transfer response as JSONResponse
    public func subAccountTransfer(subAccountUser: String, isDeposit: Bool, usd: Decimal) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let action: [String: any Sendable] = [
            "type": "subAccountTransfer",
            "subAccountUser": subAccountUser,
            "isDeposit": isDeposit,
            "usd": usd.description
        ]

        return try await executeTransferAction(action: action, timestamp: timestamp, isUserSigned: false)
    }

    /// Transfer USD to/from vault
    /// - Parameters:
    ///   - vaultAddress: Vault address
    ///   - isDeposit: true to deposit to vault, false to withdraw
    ///   - usd: Amount in USD (in micro-USD, e.g., 1000000 = $1)
    /// - Returns: Transfer response as JSONResponse
    public func vaultUsdTransfer(vaultAddress: String, isDeposit: Bool, usd: Int) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let action: [String: any Sendable] = [
            "type": "vaultTransfer",
            "vaultAddress": vaultAddress,
            "isDeposit": isDeposit,
            "usd": usd
        ]

        return try await executeTransferAction(action: action, timestamp: timestamp, isUserSigned: false)
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
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let action: [String: any Sendable] = [
            "type": "sendAsset",
            "destination": destination,
            "sourceDex": sourceDex,
            "destinationDex": destinationDex,
            "token": token,
            "amount": amount.description,
            "fromSubAccount": "", // Will be set by vault if needed
            "nonce": timestamp
        ]

        return try await executeTransferAction(action: action, timestamp: timestamp, isUserSigned: true)
    }

    /// Transfer spot tokens between main account and sub account
    /// - Parameters:
    ///   - subAccountUser: Sub account address
    ///   - isDeposit: true to deposit to sub account, false to withdraw
    ///   - token: Token identifier
    ///   - amount: Amount to transfer
    /// - Returns: Transfer response as JSONResponse
    public func subAccountSpotTransfer(subAccountUser: String, isDeposit: Bool, token: String, amount: Decimal) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let action: [String: any Sendable] = [
            "type": "subAccountSpotTransfer",
            "subAccountUser": subAccountUser,
            "isDeposit": isDeposit,
            "token": token,
            "amount": amount.description
        ]

        return try await executeTransferAction(action: action, timestamp: timestamp, isUserSigned: false)
    }

    /// Approve agent for automated trading
    /// - Parameters:
    ///   - agentAddress: Agent address to approve
    ///   - agentName: Name of the agent (optional)
    /// - Returns: Approval response as JSONResponse
    public func approveAgent(agentAddress: String, agentName: String? = nil) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        var action: [String: any Sendable] = [
            "type": "approveAgent",
            "agentAddress": agentAddress
        ]

        if let agentName = agentName {
            action["agentName"] = agentName
        }

        return try await executeTransferAction(action: action, timestamp: timestamp, isUserSigned: true)
    }

    /// Execute transfer action with proper signing
    private func executeTransferAction(action: [String: any Sendable], timestamp: Int64, isUserSigned: Bool) async throws -> JSONResponse {
        let request: [String: Any]

        if isUserSigned {
            // User-signed transfers use different signing method
            request = try await createUserSignedRequest(action: action, timestamp: timestamp)
        } else {
            // L1 signed transfers
            request = try await createSignedRequest(action: action, timestamp: timestamp)
        }

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }

    /// Create user-signed request for transfers
    private func createUserSignedRequest(action: [String: any Sendable], timestamp: Int64) async throws -> [String: Any] {
        // Convert to JSONResponse for Codable compatibility
        let actionData = try JSONSerialization.data(withJSONObject: action)
        let jsonResponse = try JSONDecoder().decode(JSONResponse.self, from: actionData)

        // Use appropriate signing method based on transfer type
        let signatureHex: String
        if let type = action["type"] as? String {
            switch type {
            case "usdClassTransfer":
                signatureHex = try CryptoService.signUsdClassTransferAction(
                    action: jsonResponse,
                    privateKey: privateKey,
                    isMainnet: environment == .mainnet
                )
            case "usdSend":
                signatureHex = try CryptoService.signUsdTransferAction(
                    action: jsonResponse,
                    privateKey: privateKey,
                    isMainnet: environment == .mainnet
                )
            case "spotSend":
                signatureHex = try CryptoService.signSpotTransferAction(
                    action: jsonResponse,
                    privateKey: privateKey,
                    isMainnet: environment == .mainnet
                )
            case "sendAsset":
                signatureHex = try CryptoService.signSendAssetAction(
                    action: jsonResponse,
                    privateKey: privateKey,
                    isMainnet: environment == .mainnet
                )
            case "approveAgent":
                signatureHex = try CryptoService.signApproveAgentAction(
                    action: jsonResponse,
                    privateKey: privateKey,
                    isMainnet: environment == .mainnet
                )
            default:
                throw TradingServiceError.invalidTransferType
            }
        } else {
            throw TradingServiceError.invalidTransferType
        }

        let signature = try convertSignatureToRSV(signatureHex)

        return [
            "action": action,
            "nonce": timestamp,
            "signature": signature
        ]
    }
}