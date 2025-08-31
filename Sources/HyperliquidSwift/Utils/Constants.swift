import Foundation

/// Global constants for easy customization
public enum Constants {
    
    // MARK: - API URLs
    public static let MAINNET_API_URL = "https://api.hyperliquid.xyz"
    public static let TESTNET_API_URL = "https://api.hyperliquid-testnet.xyz"
    public static let LOCAL_API_URL = "http://localhost:3001"
    
    // MARK: - WebSocket URLs
    public static let MAINNET_WS_URL = "wss://api.hyperliquid.xyz/ws"
    public static let TESTNET_WS_URL = "wss://api.hyperliquid-testnet.xyz/ws"
    public static let LOCAL_WS_URL = "ws://localhost:3001/ws"
    
    // MARK: - API Paths
    public static let INFO_PATH = "/info"
    public static let EXCHANGE_PATH = "/exchange"
    
    // MARK: - Chain IDs
    public static let MAINNET_CHAIN_ID = 42161
    public static let TESTNET_CHAIN_ID = 421614
    
    // MARK: - Timeouts
    public static let DEFAULT_TIMEOUT: TimeInterval = 30.0
    public static let WEBSOCKET_TIMEOUT: TimeInterval = 10.0
    
    // MARK: - Retry Configuration
    public static let MAX_RETRY_COUNT = 3
    public static let RETRY_DELAY: TimeInterval = 1.0
    
    // MARK: - Trading Limits
    public static let MAX_ORDER_SIZE: Decimal = 1_000_000
    public static let MIN_ORDER_SIZE: Decimal = 0.0001
    public static let MAX_LEVERAGE = 100
    
    // MARK: - WebSocket Configuration
    public static let HEARTBEAT_INTERVAL: TimeInterval = 30.0
    public static let MAX_RECONNECT_ATTEMPTS = 5
    public static let RECONNECT_DELAY: TimeInterval = 2.0
}
