import Foundation

// Minimal models to start; extend as needed for full coverage

public struct PerpAssetInfo: Codable {
    public let name: String
    public let szDecimals: Int
}

public struct Meta: Codable {
    public let universe: [PerpAssetInfo]
    public let marginTables: [[AnyCodable]]?
}

public struct SpotToken: Codable {
    public let name: String
    public let szDecimals: Int
    public let weiDecimals: Int
    public let index: Int
    public let tokenId: String
    public let isCanonical: Bool
}

public struct SpotUniverseItem: Codable {
    public let tokens: [Int]
    public let name: String
    public let index: Int
    public let isCanonical: Bool
}

public struct SpotMeta: Codable {
    public let universe: [SpotUniverseItem]
    public let tokens: [SpotToken]
}

public struct Leverage: Codable {
    public enum Kind: String, Codable { case cross, isolated }
    public let type: Kind
    public let value: Int
    public let rawUsd: String?
}

public struct Position: Codable {
    public let coin: String
    public let entryPx: String?
    public let leverage: Leverage
    public let liquidationPx: String?
    public let marginUsed: String
    public let positionValue: String
    public let returnOnEquity: String
    public let szi: String
    public let unrealizedPnl: String
}

public struct AssetPosition: Codable {
    public let position: Position
    public let type: String
}

public struct MarginSummary: Codable {
    public let accountValue: String
    public let totalMarginUsed: String
    public let totalNtlPos: String
    public let totalRawUsd: String
}

public struct UserState: Codable {
    public let assetPositions: [AssetPosition]
    public let crossMarginSummary: MarginSummary
    public let marginSummary: MarginSummary
    public let withdrawable: String
}

public struct SpotUserBalance: Codable {
    public let coin: String
    public let available: String
    public let total: String
}

public struct SpotUserState: Codable {
    public let balances: [SpotUserBalance]
}

// Helper for unknown nested arrays in marginTables
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) { value = intVal; return }
        if let dblVal = try? container.decode(Double.self) { value = dblVal; return }
        if let strVal = try? container.decode(String.self) { value = strVal; return }
        if let boolVal = try? container.decode(Bool.self) { value = boolVal; return }
        if let arrVal = try? container.decode([AnyCodable].self) { value = arrVal; return }
        if let dictVal = try? container.decode([String: AnyCodable].self) { value = dictVal; return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as Bool: try container.encode(v)
        case let v as [AnyCodable]: try container.encode(v)
        case let v as [String: AnyCodable]: try container.encode(v)
        default:
            throw EncodingError.invalidValue(value, .init(codingPath: container.codingPath, debugDescription: "Unsupported JSON value"))
        }
    }
}



