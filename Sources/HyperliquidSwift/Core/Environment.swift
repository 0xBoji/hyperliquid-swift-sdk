import Foundation

/// Hyperliquid environment configuration
public enum HyperliquidEnvironment: String, CaseIterable, Sendable {
    case mainnet = "mainnet"
    case testnet = "testnet"
    
    /// API base URL
    public var apiURL: String {
        switch self {
        case .mainnet:
            return Constants.API.mainnetURL
        case .testnet:
            return Constants.API.testnetURL
        }
    }
    
    /// WebSocket URL
    public var webSocketURL: String {
        switch self {
        case .mainnet:
            return Constants.API.mainnetWS
        case .testnet:
            return Constants.API.testnetWS
        }
    }
    
    /// Chain ID for EIP-712 signing
    public var chainId: Int {
        switch self {
        case .mainnet:
            return Constants.ChainID.mainnet
        case .testnet:
            return Constants.ChainID.testnet
        }
    }
}
