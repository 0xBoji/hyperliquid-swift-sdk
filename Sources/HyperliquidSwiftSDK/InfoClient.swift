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
}


