import Foundation

/// Base protocol for all Hyperliquid services
public protocol HyperliquidService: Actor {
    /// The environment this service operates in
    var environment: HyperliquidEnvironment { get }
}

/// Protocol for services that require HTTP networking
public protocol HTTPService: HyperliquidService {
    /// HTTP client for making requests
    var httpClient: HTTPClient { get }
}

/// Protocol for services that require WebSocket connectivity
public protocol WebSocketService: HyperliquidService {
    /// WebSocket manager for real-time data
    var webSocketManager: WebSocketManager? { get }
}

/// Protocol for services that require authentication
public protocol AuthenticatedService: HyperliquidService {
    /// Private key for signing requests
    var privateKey: PrivateKey { get }
    
    /// Wallet address derived from private key
    var walletAddress: String { get }
}
