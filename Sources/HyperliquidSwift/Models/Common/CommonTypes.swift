import Foundation

// MARK: - Basic Types

/// Order ID type
public typealias OrderID = UInt64

/// Client Order ID type  
public typealias ClientOrderID = String

/// Asset symbol type
public typealias AssetSymbol = String

/// Wallet address type
public typealias WalletAddress = String

// MARK: - Enums

/// Order side enumeration
public enum Side: String, Codable, CaseIterable, Sendable {
    case buy = "B"
    case sell = "A"
    
    public var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
}

/// Order type enumeration
public enum OrderType: String, Codable, CaseIterable, Sendable {
    case limit = "@"
    case market = "M"
    case stop = "S"
    case stopLimit = "SL"
    case takeProfit = "TP"
    case takeProfitLimit = "TPL"
    
    public var displayName: String {
        switch self {
        case .limit: return "Limit"
        case .market: return "Market"
        case .stop: return "Stop"
        case .stopLimit: return "Stop Limit"
        case .takeProfit: return "Take Profit"
        case .takeProfitLimit: return "Take Profit Limit"
        }
    }
}

/// Time in force enumeration
public enum TimeInForce: String, Codable, CaseIterable, Sendable {
    case gtc = "Gtc"        // Good Till Cancelled
    case ioc = "Ioc"        // Immediate Or Cancel
    case alo = "Alo"        // Add Liquidity Only
    
    public var displayName: String {
        switch self {
        case .gtc: return "Good Till Cancelled"
        case .ioc: return "Immediate Or Cancel"
        case .alo: return "Add Liquidity Only"
        }
    }
}

// MARK: - Asset Information

/// Asset information structure
public struct AssetInfo: Codable, Sendable, Hashable {
    public let name: String
    public let szDecimals: Int
    public let maxLeverage: Int
    public let onlyIsolated: Bool

    public init(name: String, szDecimals: Int, maxLeverage: Int, onlyIsolated: Bool = false) {
        self.name = name
        self.szDecimals = szDecimals
        self.maxLeverage = maxLeverage
        self.onlyIsolated = onlyIsolated
    }

    // Custom decoding to handle missing onlyIsolated field
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        szDecimals = try container.decode(Int.self, forKey: .szDecimals)
        maxLeverage = try container.decode(Int.self, forKey: .maxLeverage)
        // Default to false if onlyIsolated is missing
        onlyIsolated = try container.decodeIfPresent(Bool.self, forKey: .onlyIsolated) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case name, szDecimals, maxLeverage, onlyIsolated
    }
}

/// Spot asset information
public struct SpotAssetInfo: Codable, Sendable, Hashable {
    public let name: String
    public let szDecimals: Int

    public init(name: String, szDecimals: Int = 6) {
        self.name = name
        self.szDecimals = szDecimals
    }

    // Custom decoding to handle missing szDecimals field
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        // Default to 6 if szDecimals is missing (common for spot assets)
        szDecimals = try container.decodeIfPresent(Int.self, forKey: .szDecimals) ?? 6
    }

    private enum CodingKeys: String, CodingKey {
        case name, szDecimals
    }
}

/// Token information
public struct TokenInfo: Codable, Sendable, Hashable {
    public let name: String
    public let szDecimals: Int
    public let weiDecimals: Int
    public let index: Int
    public let tokenId: String
    public let isCanonical: Bool
    
    public init(name: String, szDecimals: Int, weiDecimals: Int, index: Int, tokenId: String, isCanonical: Bool) {
        self.name = name
        self.szDecimals = szDecimals
        self.weiDecimals = weiDecimals
        self.index = index
        self.tokenId = tokenId
        self.isCanonical = isCanonical
    }
}

// MARK: - Metadata

/// Universe metadata for perpetual assets
public struct Meta: Codable, Sendable {
    public let universe: [AssetInfo]
    
    public init(universe: [AssetInfo]) {
        self.universe = universe
    }
}

/// Spot market metadata
public struct SpotMeta: Codable, Sendable {
    public let universe: [SpotAssetInfo]
    public let tokens: [TokenInfo]
    
    public init(universe: [SpotAssetInfo], tokens: [TokenInfo]) {
        self.universe = universe
        self.tokens = tokens
    }
}
