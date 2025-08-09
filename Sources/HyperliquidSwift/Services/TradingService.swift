import Foundation

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

    // Modify an existing order
    func modifyOrder(oid: UInt64, coin: String, newPrice: Decimal, newSize: Decimal) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // Get asset ID for the coin
        let assetId = try await getAssetId(for: coin)

        // Create modify request
        let modifyRequest: [String: any Sendable] = [
            "oid": oid,
            "order": [
                "a": assetId,
                "b": true, // This should be determined from original order, but simplified for now
                "p": floatToWire(newPrice),
                "s": floatToWire(newSize),
                "r": false,
                "t": ["limit": ["tif": "Gtc"]]
            ] as [String: any Sendable]
        ]

        let action: [String: any Sendable] = [
            "type": "modify",
            "modifies": [modifyRequest]
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

    // Batch modify orders (Python: bulk_modify_orders_new)
    func bulkModifyOrders(_ modifies: [ModifyRequest]) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        var modifyWires: [[String: any Sendable]] = []
        for m in modifies {
            let assetId = try await getAssetId(for: m.order.coin)
            let orderWire: [String: any Sendable] = [
                "a": assetId,
                "b": m.order.isBuy,
                "p": m.order.orderType == .market ? "@0" : floatToWire(m.order.px),
                "s": floatToWire(m.order.sz),
                "r": m.order.reduceOnly,
                "t": m.order.orderType == .market ? ["market": [:] as [String: any Sendable]] : ["limit": ["tif": "Gtc"] as [String: any Sendable]]
            ]
            var modify: [String: any Sendable] = ["order": orderWire]
            if let oid = m.oid { modify["oid"] = oid }
            if let cloid = m.cloid { modify["oid"] = cloid } // API uses same field key
            modifyWires.append(modify)
        }
        let action: [String: any Sendable] = [
            "type": "batchModify",
            "modifies": modifyWires
        ]
        let request = try await createSignedRequest(action: action, timestamp: timestamp)
        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }

    // Update leverage (Python: update_leverage)
    func updateLeverage(coin: String, leverage: Int, isCross: Bool = true) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let assetId = try await getAssetId(for: coin)
        let action: [String: any Sendable] = [
            "type": "updateLeverage",
            "asset": assetId,
            "isCross": isCross,
            "leverage": leverage
        ]
        let request = try await createSignedRequest(action: action, timestamp: timestamp)
        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }

    // Update isolated margin (Python: update_isolated_margin)
    func updateIsolatedMargin(coin: String, amountUsd: Decimal, isBuy: Bool = true) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let assetId = try await getAssetId(for: coin)
        // Convert USD decimal to integer cents-like format string similar to float_to_usd_int
        // Hyperliquid expects integer ntli units; we'll scale by 1e6 which is typical for USD int
        let scaled = (amountUsd as NSDecimalNumber).multiplying(by: NSDecimalNumber(mantissa: 1, exponent: 6, isNegative: false))
        let action: [String: any Sendable] = [
            "type": "updateIsolatedMargin",
            "asset": assetId,
            "isBuy": isBuy,
            "ntli": scaled.stringValue
        ]
        let request = try await createSignedRequest(action: action, timestamp: timestamp)
        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }

    // Set referrer code (Python: set_referrer)
    func setReferrer(code: String) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let action: [String: any Sendable] = [
            "type": "setReferrer",
            "code": code
        ]
        let request = try await createSignedRequest(action: action, timestamp: timestamp)
        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }

    // Create Sub Account (Python: create_sub_account)
    func createSubAccount(name: String) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let action: [String: any Sendable] = [
            "type": "createSubAccount",
            "name": name
        ]
        let request = try await createSignedRequest(action: action, timestamp: timestamp)
        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }



    // Place multiple orders in a single request (bulk orders)
    func bulkOrders(_ orders: [BulkOrderRequest]) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // Convert bulk order requests to order wires
        var orderWires: [[String: any Sendable]] = []

        for order in orders {
            let assetId = try await getAssetId(for: order.coin)

            let orderWire: [String: any Sendable] = [
                "a": assetId,
                "b": order.isBuy,
                "p": order.orderType == .market ? "@0" : floatToWire(order.px),
                "s": floatToWire(order.sz),
                "r": order.reduceOnly,
                "t": order.orderType == .market ?
                    ["market": [:] as [String: any Sendable]] :
                    ["limit": ["tif": "Gtc"] as [String: any Sendable]]
            ]

            orderWires.append(orderWire)
        }

        let action: [String: any Sendable] = [
            "type": "order",
            "orders": orderWires,
            "grouping": "na"
        ]

        let request = try await createSignedRequest(action: action, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }

    // Cancel order by client order ID
    func cancelOrderByCloid(coin: String, cloid: String) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        // Get asset ID for the coin
        let assetId = try await getAssetId(for: coin)

        let cancelRequest: [String: any Sendable] = [
            "a": assetId,
            "o": cloid  // Use cloid directly as string
        ]

        let action: [String: any Sendable] = [
            "type": "cancel",
            "cancels": [cancelRequest]
        ]

        let request = try await createSignedRequest(action: action, timestamp: timestamp)

        return try await httpClient.postAndDecode(
            path: "/exchange",
            payload: request,
            responseType: JSONResponse.self
        )
    }

    // Schedule cancellation of all orders at a specific time
    func scheduleCancel(time: Int64?) async throws -> JSONResponse {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        let action: [String: any Sendable] = [
            "type": "scheduleCancel",
            "time": time ?? NSNull()  // null for immediate cancel, timestamp for scheduled
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
}