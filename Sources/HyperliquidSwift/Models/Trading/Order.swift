import Foundation

// MARK: - Order Models

/// Order request structure
public struct OrderRequest: Codable, Sendable {
    public let asset: AssetSymbol
    public let isBuy: Bool
    public let limitPx: Decimal
    public let sz: Decimal
    public let reduceOnly: Bool
    public let orderType: OrderType
    public let timeInForce: TimeInForce?
    public let cloid: ClientOrderID?
    
    public init(
        asset: AssetSymbol,
        isBuy: Bool,
        limitPx: Decimal,
        sz: Decimal,
        reduceOnly: Bool = false,
        orderType: OrderType = .limit,
        timeInForce: TimeInForce? = nil,
        cloid: ClientOrderID? = nil
    ) {
        self.asset = asset
        self.isBuy = isBuy
        self.limitPx = limitPx
        self.sz = sz
        self.reduceOnly = reduceOnly
        self.orderType = orderType
        self.timeInForce = timeInForce
        self.cloid = cloid
    }
}

/// Open order information
public struct OpenOrder: Codable, Sendable {
    public let coin: String
    public let side: Side
    public let sz: Decimal
    public let px: Decimal
    public let oid: OrderID
    public let timestamp: Int64
    public let origSz: Decimal
    public let cloid: ClientOrderID?
    
    public init(
        coin: String,
        side: Side,
        sz: Decimal,
        px: Decimal,
        oid: OrderID,
        timestamp: Int64,
        origSz: Decimal,
        cloid: ClientOrderID? = nil
    ) {
        self.coin = coin
        self.side = side
        self.sz = sz
        self.px = px
        self.oid = oid
        self.timestamp = timestamp
        self.origSz = origSz
        self.cloid = cloid
    }
}

/// Order status information
public struct OrderStatus: Codable, Sendable {
    public let order: OpenOrder
    public let status: String
    public let statusTimestamp: Int64
    
    public init(order: OpenOrder, status: String, statusTimestamp: Int64) {
        self.order = order
        self.status = status
        self.statusTimestamp = statusTimestamp
    }
}

/// Order fill information
public struct Fill: Codable, Sendable {
    public let coin: String
    public let px: Decimal
    public let sz: Decimal
    public let side: Side
    public let time: Date
    public let startPosition: Decimal
    public let dir: String
    public let closedPnl: Decimal
    public let hash: String
    public let oid: OrderID
    public let crossed: Bool
    public let fee: Decimal
    public let liquidation: Bool?
    
    public init(
        coin: String,
        px: Decimal,
        sz: Decimal,
        side: Side,
        time: Date,
        startPosition: Decimal,
        dir: String,
        closedPnl: Decimal,
        hash: String,
        oid: OrderID,
        crossed: Bool,
        fee: Decimal,
        liquidation: Bool? = nil
    ) {
        self.coin = coin
        self.px = px
        self.sz = sz
        self.side = side
        self.time = time
        self.startPosition = startPosition
        self.dir = dir
        self.closedPnl = closedPnl
        self.hash = hash
        self.oid = oid
        self.crossed = crossed
        self.fee = fee
        self.liquidation = liquidation
    }
}

/// Position information
public struct Position: Codable, Sendable {
    public let coin: String
    public let szi: Decimal      // Size (positive for long, negative for short)
    public let entryPx: Decimal?
    public let positionValue: Decimal
    public let unrealizedPnl: Decimal
    public let returnOnEquity: Decimal
    public let leverage: Decimal
    public let maxLeverage: Int
    public let marginUsed: Decimal
    
    /// Computed properties
    public var side: Side {
        return szi >= 0 ? .buy : .sell
    }
    
    public var absoluteSize: Decimal {
        return abs(szi)
    }
    
    public var isLong: Bool {
        return szi > 0
    }
    
    public var isShort: Bool {
        return szi < 0
    }
    
    public init(
        coin: String,
        szi: Decimal,
        entryPx: Decimal?,
        positionValue: Decimal,
        unrealizedPnl: Decimal,
        returnOnEquity: Decimal,
        leverage: Decimal,
        maxLeverage: Int,
        marginUsed: Decimal
    ) {
        self.coin = coin
        self.szi = szi
        self.entryPx = entryPx
        self.positionValue = positionValue
        self.unrealizedPnl = unrealizedPnl
        self.returnOnEquity = returnOnEquity
        self.leverage = leverage
        self.maxLeverage = maxLeverage
        self.marginUsed = marginUsed
    }
}
