import Foundation

public final class ExchangeClient {
    private let transport: NetworkTransport
    private let baseURL: URL
    private let signer: EvmSigner
    private let info: InfoClient
    private let isMainnet: Bool

    public init(baseURL: URL, privateKeyHex: String, transport: NetworkTransport = URLSessionTransport()) throws {
        self.transport = transport
        self.baseURL = baseURL
        self.signer = try EvmSigner(privateKeyHex: privateKeyHex)
        self.info = InfoClient(config: .init(baseURL: baseURL), transport: transport)
        self.isMainnet = baseURL.host?.contains("testnet") == false
    }
    
    public func getAccountAddress() throws -> String {
        return try signer.getAddress()
    }
    
    public var evmSigner: EvmSigner {
        return signer
    }

    // Market order via aggressive IOC limit at slippage around mid
    public func marketOpen(coin: String, isBuy: Bool, sz: Double, slippage: Double = 0.01) async throws -> Any {
        let mids: [String: String] = try await info.allMids()
        guard let midStr = mids[coin], let mid = Double(midStr) else { throw NSError(domain: "mid", code: -1) }
        let roundedPx = try await slippagePrice(coin: coin, basePx: mid, isBuy: isBuy, slippage: slippage)
        return try await order(coin: coin, isBuy: isBuy, sz: sz, limitPx: roundedPx, orderType: ["limit": ["tif": "Ioc"]])
    }

    public func order(coin: String, isBuy: Bool, sz: Double, limitPx: Double, orderType: [String: Any], reduceOnly: Bool = false, cloid: String? = nil) async throws -> Any {
        // Resolve asset id via meta
        let meta = try await info.meta()
        guard let asset = meta.universe.firstIndex(where: { $0.name == coin }) else { throw NSError(domain: "asset", code: -1) }

        var t = normalizeOrderType(orderType)
        // Keep order keys and stable ordering to match Python
        var pairs: [(String, Any)] = [("a", asset), ("b", isBuy), ("p", formatWire(limitPx)), ("s", formatWire(sz)), ("r", reduceOnly), ("t", t)]
        if let cl = cloid { pairs.append(("c", cl)) }
        let orderWire = OrderedMap(pairs)

        let action = OrderedMap([
            ("type", "order"),
            ("orders", [orderWire]),
            ("grouping", "na"),
        ])
        // Sign L1 action
        let nonce = Int(Date().timeIntervalSince1970 * 1000)
        let payload = try signL1(orderedAction: action, vaultAddress: nil, nonce: nonce, expiresAfter: nil)

        var body: [String: Any] = [
            "action": [
                "type": "order",
                "orders": [
                    ["a": asset, "b": isBuy, "p": formatWire(limitPx), "s": formatWire(sz), "r": reduceOnly, "t": t].merging(cloid != nil ? ["c": cloid!] : [:]) { $1 }
                ],
                "grouping": "na",
            ],
            "signature": ["r": payload.r, "s": payload.s, "v": payload.v],
            "nonce": nonce,
        ]
        // Don't include vaultAddress and expiresAfter for order actions (like Python SDK)

        // Debug: print payload JSON for verification
        if let dbg = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted]), let dbgStr = String(data: dbg, encoding: .utf8) {
            print("[Exchange Debug] Request body to /exchange:\n\(dbgStr)")
        }

        let data = try await (transport as! URLSessionTransport).postJSON(baseURL: baseURL, path: "/exchange", jsonBody: body, timeout: nil)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func signL1(orderedAction: OrderedMap, vaultAddress: String?, nonce: Int, expiresAfter: Int?) throws -> EcdsaSignature {
        // hashAction per Python: msgpack(action) || nonce || vaultFlag+(addr?) || expiresFlag+(u64?)
        var payload = MsgPack.encode(orderedAction)
        var n = UInt64(nonce).bigEndian
        payload.append(Data(bytes: &n, count: MemoryLayout<UInt64>.size))
        if let _ = vaultAddress {
            payload.append(0x01)
            // TODO: append 20-byte address here if used
        } else {
            payload.append(0x00)
        }
        if let exp = expiresAfter {
            payload.append(0x00)
            var e = UInt64(exp).bigEndian
            payload.append(Data(bytes: &e, count: MemoryLayout<UInt64>.size))
        }
        let connectionId = keccak256(payload)
        let source = isMainnet ? "a" : "b"
        let digest = eip712HashAgent(source: source, connectionId: connectionId)
        return try signer.signTypedData(digest)
    }

    private func normalizeOrderType(_ t: [String: Any]) -> [String: Any] {
        if let trigger = t["trigger"] as? [String: Any], let px = trigger["triggerPx"] as? Double {
            var trig = trigger
            trig["triggerPx"] = formatWire(px)
            return ["trigger": trig]
        }
        return t
    }

    private func formatWire(_ x: Double) -> String {
        var s = String(format: "%.8f", x)
        // Normalize -0.x to 0.x before trimming
        if s.hasPrefix("-0") { s.removeFirst() }
        // Trim only trailing zeros
        if let dotIndex = s.firstIndex(of: ".") {
            while s.last == "0" { s.removeLast() }
            if s.last == "." { s.removeLast() }
            if s.isEmpty { s = "0" }
            // Ensure leading zero for decimals like .01
            if s.first == "." { s = "0" + s }
        }
        return s
    }
}

// MARK: - Python-compatible slippage price rounding
extension ExchangeClient {
    private func slippagePrice(coin: String, basePx: Double, isBuy: Bool, slippage: Double) async throws -> Double {
        let (isSpot, szDecimals) = try await fetchSzDecimals(coin: coin)
        var px = basePx
        px *= isBuy ? (1 + slippage) : (1 - slippage)
        // 5 significant figures
        px = roundToSignificant(px, sigFigs: 5)
        // Round to (6 if perp else 8) - szDecimals decimal places
        let places = (isSpot ? 8 : 6) - szDecimals
        return round(px, places: max(0, places))
    }

    private func fetchSzDecimals(coin: String) async throws -> (Bool, Int) {
        // Check perp meta first
        let meta = try await info.meta()
        if let asset = meta.universe.first(where: { $0.name == coin }) {
            return (false, asset.szDecimals)
        }
        // Then spot
        let spot = try await info.spotMeta()
        if let uni = spot.universe.first(where: { $0.name == coin }) {
            let baseIndex = uni.tokens.first ?? 0
            let baseToken = spot.tokens[baseIndex]
            return (true, baseToken.szDecimals)
        }
        throw NSError(domain: "coin_not_found", code: -1)
    }

    private func roundToSignificant(_ x: Double, sigFigs: Int) -> Double {
        guard x != 0 else { return 0 }
        let d = ceil(log10(abs(x)))
        let power = sigFigs - Int(d)
        let factor = pow(10.0, Double(power))
        return (x * factor).rounded() / factor
    }

    private func round(_ x: Double, places: Int) -> Double {
        let f = pow(10.0, Double(places))
        return (x * f).rounded() / f
    }
}

// MARK: - Order Management
extension ExchangeClient {
    /// Cancel an order by order ID (backward compatibility - requires coin parameter)
    public func cancel(coin: String, oid: Int) async throws -> Any {
        // Get asset ID for the coin
        let meta = try await info.meta()
        guard let asset = meta.universe.firstIndex(where: { $0.name == coin }) else { 
            throw NSError(domain: "asset", code: -1) 
        }
        
        let action = OrderedMap([
            ("type", "cancel"),
            ("cancels", [["a": asset, "o": oid]]),
        ])
        
        let nonce = Int(Date().timeIntervalSince1970 * 1000)
        let payload = try signL1(orderedAction: action, vaultAddress: nil, nonce: nonce, expiresAfter: nil)
        
        let body: [String: Any] = [
            "action": [
                "type": "cancel",
                "cancels": [["a": asset, "o": oid]]
            ],
            "signature": ["r": payload.r, "s": payload.s, "v": payload.v],
            "nonce": nonce,
        ]
        
        // Debug: print payload JSON for verification
        if let dbg = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted]), let dbgStr = String(data: dbg, encoding: .utf8) {
            print("[Exchange Debug] Cancel request body to /exchange:\n\(dbgStr)")
        }
        
        let data = try await (transport as! URLSessionTransport).postJSON(baseURL: baseURL, path: "/exchange", jsonBody: body, timeout: nil)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Cancel an order by client order ID (cloid)
    public func cancelByCloid(cloid: String) async throws -> Any {
        let action = OrderedMap([
            ("type", "cancelByCloid"),
            ("cancels", [["cloid": cloid]]),
        ])
        
        let nonce = Int(Date().timeIntervalSince1970 * 1000)
        let payload = try signL1(orderedAction: action, vaultAddress: nil, nonce: nonce, expiresAfter: nil)
        
        let body: [String: Any] = [
            "action": [
                "type": "cancelByCloid",
                "cancels": [["cloid": cloid]]
            ],
            "signature": ["r": payload.r, "s": payload.s, "v": payload.v],
            "nonce": nonce,
        ]
        
        // Debug: print payload JSON for verification
        if let dbg = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted]), let dbgStr = String(data: dbg, encoding: .utf8) {
            print("[Exchange Debug] CancelByCloid request body to /exchange:\n\(dbgStr)")
        }
        
        let data = try await (transport as! URLSessionTransport).postJSON(baseURL: baseURL, path: "/exchange", jsonBody: body, timeout: nil)
        return String(data: data, encoding: .utf8) ?? ""
    }
}


