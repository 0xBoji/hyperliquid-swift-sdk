import Foundation

public struct InfoClientConfig {
    public let baseURL: URL
    public let timeout: TimeInterval?

    public init(baseURL: URL, timeout: TimeInterval? = nil) {
        self.baseURL = baseURL
        self.timeout = timeout
    }
}

public final class InfoClient {
    public enum Network: String {
        case mainnet
        case testnet
    }

    public static func defaultURL(for network: Network) -> URL {
        switch network {
        case .mainnet:
            return URL(string: "https://api.hyperliquid.xyz")!
        case .testnet:
            return URL(string: "https://api.hyperliquid-testnet.xyz")!
        }
    }

    private let transport: NetworkTransport
    private let config: InfoClientConfig

    public init(config: InfoClientConfig, transport: NetworkTransport = URLSessionTransport()) {
        self.config = config
        self.transport = transport
    }

    // MARK: - Requests

    public func meta(dex: String? = nil) async throws -> Meta {
        struct Body: Encodable { let type = "meta"; let dex: String? }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(dex: dex), timeout: config.timeout)
    }

    public func spotMeta() async throws -> SpotMeta {
        struct Body: Encodable { let type = "spotMeta" }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(), timeout: config.timeout)
    }

    public func clearinghouseState(user: String, dex: String? = nil) async throws -> UserState {
        struct Body: Encodable { let type = "clearinghouseState"; let user: String; let dex: String? }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user, dex: dex), timeout: config.timeout)
    }

    public func spotClearinghouseState(user: String) async throws -> SpotUserState {
        struct Body: Encodable { let type = "spotClearinghouseState"; let user: String }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user), timeout: config.timeout)
    }

    public func allMids(dex: String? = nil) async throws -> [String: String] {
        struct Body: Encodable { let type = "allMids"; let dex: String? }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(dex: dex), timeout: config.timeout)
    }

    public func userFills(user: String) async throws -> [UserFill] {
        struct Body: Encodable { let type = "userFills"; let user: String }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user), timeout: config.timeout)
    }

    public func openOrders(user: String) async throws -> [OpenOrder] {
        struct Body: Encodable { let type = "openOrders"; let user: String }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user), timeout: config.timeout)
    }

    public func fundingHistory(coin: String, startTime: Int64, endTime: Int64? = nil) async throws -> [FundingHistory] {
        struct Body: Encodable {
            let type = "fundingHistory"
            let coin: String
            let startTime: Int64
            let endTime: Int64?
        }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(coin: coin, startTime: startTime, endTime: endTime), timeout: config.timeout)
    }

    public func l2Snapshot(coin: String) async throws -> L2Book {
        struct Body: Encodable { let type = "l2Book"; let coin: String }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(coin: coin), timeout: config.timeout)
    }

    public func candlesSnapshot(coin: String, interval: String, startTime: Int64, endTime: Int64) async throws -> [Candle] {
        struct Req: Encodable {
            let coin: String
            let interval: String
            let startTime: Int64
            let endTime: Int64
        }
        struct Body: Encodable {
            let type = "candleSnapshot"
            let req: Req
        }
        let req = Req(coin: coin, interval: interval, startTime: startTime, endTime: endTime)
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(req: req), timeout: config.timeout)
    }

    public func userFundingHistory(user: String, startTime: Int64, endTime: Int64? = nil) async throws -> [UserFunding] {
        struct Body: Encodable {
            let type = "userFunding"
            let user: String
            let startTime: Int64
            let endTime: Int64?
        }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user, startTime: startTime, endTime: endTime), timeout: config.timeout)
    }

    public func metaAndAssetCtxs() async throws -> MetaAndAssetCtxs {
        struct Body: Encodable { let type = "metaAndAssetCtxs" }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(), timeout: config.timeout)
    }

    public func orderStatus(user: String, oid: Int64) async throws -> OrderStatus {
        struct Body: Encodable {
            let type = "orderStatus"
            let user: String
            let oid: Int64
        }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user, oid: oid), timeout: config.timeout)
    }

    public func userFillsByTime(user: String, startTime: Int64, endTime: Int64? = nil) async throws -> [UserFill] {
        struct Body: Encodable {
            let type = "userFillsByTime"
            let user: String
            let startTime: Int64
            let endTime: Int64?
        }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user, startTime: startTime, endTime: endTime), timeout: config.timeout)
    }

    public func historicalOrders(user: String) async throws -> [HistoricalOrder] {
        struct Body: Encodable { let type = "historicalOrders"; let user: String }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user), timeout: config.timeout)
    }

    public func frontendOpenOrders(user: String) async throws -> [FrontendOpenOrder] {
        struct Body: Encodable { let type = "frontendOpenOrders"; let user: String }
        return try await transport.post(baseURL: config.baseURL, path: "/info", body: Body(user: user), timeout: config.timeout)
    }











}


