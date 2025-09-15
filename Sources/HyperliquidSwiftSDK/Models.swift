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

public struct UserFill: Codable {
    public let closedPnl: String
    public let coin: String
    public let crossed: Bool
    public let dir: String
    public let hash: String
    public let oid: Int64
    public let px: String
    public let side: String
    public let startPosition: String
    public let sz: String
    public let time: Int64
}

public struct OpenOrder: Codable {
    public let coin: String
    public let limitPx: String
    public let oid: Int64
    public let side: String
    public let sz: String
    public let timestamp: Int64
}

public struct FundingHistory: Codable {
    public let coin: String
    public let fundingRate: String
    public let premium: String
    public let time: Int64
}

public struct L2BookLevel: Codable {
    public let n: Int
    public let px: String
    public let sz: String
}

public struct L2Book: Codable {
    public let coin: String
    public let levels: [[L2BookLevel]]
    public let time: Int64
}

public struct Candle: Codable {
    public let T: Int64
    public let c: String
    public let h: String
    public let i: String
    public let l: String
    public let n: Int
    public let o: String
    public let s: String
    public let t: Int64
    public let v: String
}

public struct UserFunding: Codable {
    public let time: Int64
    public let coin: String
    public let usdc: String
    public let szi: String
    public let fundingRate: String
}

public struct AssetCtx: Codable {
    public let dayNtlVlm: String
    public let funding: String
    public let impactPxs: [String]?
    public let markPx: String
    public let midPx: String?
    public let openInterest: String
    public let oraclePx: String
    public let premium: String?
    public let prevDayPx: String
}

public struct MetaAndAssetCtxs: Codable {
    public let meta: Meta
    public let assetCtxs: [AssetCtx]

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.meta = try container.decode(Meta.self)
        self.assetCtxs = try container.decode([AssetCtx].self)
    }
}

public struct OrderType: Codable {
    public struct Limit: Codable {
        public let tif: String
    }
    public struct Trigger: Codable {
        public let triggerPx: String
        public let tpsl: String
    }

    public let limit: Limit?
    public let trigger: Trigger?
}

public struct Order: Codable {
    public let asset: Int
    public let isBuy: Bool
    public let reduceOnly: Bool
    public let limitPx: String
    public let sz: String
    public let orderType: OrderType
}

public struct OrderInfo: Codable {
    public let order: Order
    public let oid: Int64
    public let status: String
    public let timestamp: Int64
}

public struct OrderStatus: Codable {
    public let order: OrderInfo?
    public let status: String
}

public struct HistoricalOrder: Codable {
    public let coin: String
    public let side: String
    public let limitPx: String
    public let sz: String
    public let oid: Int64
    public let status: String
    public let timestamp: Int64
}

public struct FrontendOpenOrder: Codable {
    public let coin: String
    public let isPositionTpsl: Bool
    public let isTrigger: Bool
    public let limitPx: String
    public let oid: Int64
    public let orderType: String
    public let origSz: String
    public let reduceOnly: Bool
    public let side: String
    public let sz: String
    public let tif: String?
    public let timestamp: Int64
    public let triggerCondition: String
    public let triggerPx: String
    public let children: [FrontendOpenOrder]?
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



