import Foundation

/// Global constants for maintainability
public enum Constants {
    
    // MARK: - SDK Info
    public static let sdkName = "HyperliquidSwift"
    public static let sdkVersion = "1.0.0"
    public static let userAgent = "\(sdkName)/\(sdkVersion)"
    
    // MARK: - API Endpoints
    public enum API {
        public static let mainnetURL = "https://api.hyperliquid.xyz"
        public static let testnetURL = "https://api.hyperliquid-testnet.xyz"
        public static let mainnetWS = "wss://api.hyperliquid.xyz/ws"
        public static let testnetWS = "wss://api.hyperliquid-testnet.xyz/ws"
        
        public static let infoPath = "/info"
        public static let exchangePath = "/exchange"
    }
    
    // MARK: - Chain IDs
    public enum ChainID {
        public static let mainnet = 42161    // Arbitrum One
        public static let testnet = 421614   // Arbitrum Sepolia
    }
    
    // MARK: - Network Config
    public enum Network {
        public static let timeout: TimeInterval = 30.0
        public static let retryCount = 3
        public static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Crypto
    public enum Crypto {
        public static let privateKeyLength = 32      // bytes
        public static let privateKeyHexLength = 64  // hex chars
        public static let addressLength = 20        // bytes
    }
    
    // MARK: - HTTP Headers
    public enum Headers {
        public static let contentType = "Content-Type"
        public static let userAgent = "User-Agent"
        public static let accept = "Accept"
        public static let jsonValue = "application/json"
    }
    
    // MARK: - Trading Limits
    public enum Trading {
        public static let maxOrderSize = Decimal(1_000_000)
        public static let minOrderSize = Decimal(0.0001)
        public static let maxLeverage = 100
    }
    
    // MARK: - WebSocket
    public enum WebSocket {
        public static let heartbeatInterval: TimeInterval = 30.0
        public static let maxReconnectAttempts = 5
        public static let reconnectDelay: TimeInterval = 2.0

        public enum Channels {
            public static let allMids = "allMids"
            public static let l2Book = "l2Book"
            public static let trades = "trades"
            public static let userEvents = "userEvents"
        }
    }

    // MARK: - Error Codes
    public enum ErrorCodes {
        public static let networkError = "NETWORK_ERROR"
        public static let authenticationRequired = "AUTHENTICATION_REQUIRED"
        public static let invalidPrivateKey = "INVALID_PRIVATE_KEY"
        public static let invalidAddress = "INVALID_ADDRESS"
        public static let invalidOrderSize = "INVALID_ORDER_SIZE"
    }
}
