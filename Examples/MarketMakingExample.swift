import Foundation
import HyperliquidSwift

/// Market Making Strategy Example
/// Similar to Python SDK's basic_adding.py
public struct MarketMakingExample {
    
    // MARK: - Configuration Constants
    private static let DEPTH: Decimal = 0.003 // 0.3% from best bid/offer
    private static let ALLOWABLE_DEVIATION: Decimal = 0.5 // 50% of target depth
    private static let MAX_POSITION: Decimal = 1.0 // Max position size
    private static let COIN = "ETH" // Trading pair
    private static let POLL_INTERVAL: TimeInterval = 10.0 // Polling interval
    
    private let client: HyperliquidClient
    private let userAddress: String
    
    public init(client: HyperliquidClient, userAddress: String) {
        self.client = client
        self.userAddress = userAddress
    }
    
    /// Run the market making strategy
    public func run() async throws {
        print("🚀 Starting Market Making Strategy")
        print("Coin: \(Self.COIN)")
        print("Depth: \(Self.DEPTH * 100)%")
        print("Max Position: \(Self.MAX_POSITION)")
        
        while true {
            do {
                try await executeStrategy()
                try await Task.sleep(nanoseconds: UInt64(Self.POLL_INTERVAL * 1_000_000_000))
            } catch {
                print("❌ Strategy error: \(error)")
                try await Task.sleep(nanoseconds: UInt64(5 * 1_000_000_000))
            }
        }
    }
    
    private func executeStrategy() async throws {
        // Get current market data
        let allMids = try await client.getAllMids()
        let l2Book = try await client.getL2Book(coin: Self.COIN)
        
        guard let currentPrice = allMids[Self.COIN] else {
            throw MarketMakingError.invalidPrice
        }
        let price = currentPrice
        
        // Calculate target prices
        let bidPrice = price * (1 - Self.DEPTH)
        let askPrice = price * (1 + Self.DEPTH)
        
        // Get current positions and orders
        let userState = try await client.getUserState(address: userAddress)
        let openOrders = try await client.getOpenOrders()
        
        // Calculate current position
        let currentPosition = calculatePosition(userState: userState)
        
        // Place orders based on position
        try await placeOrders(
            currentPosition: currentPosition,
            bidPrice: bidPrice,
            askPrice: askPrice,
            openOrders: openOrders
        )
        
        print("📊 Market Making Update:")
        print("  Current Price: $\(price)")
        print("  Bid Price: $\(bidPrice)")
        print("  Ask Price: $\(askPrice)")
        print("  Position: \(currentPosition)")
    }
    
    private func calculatePosition(userState: UserState) -> Decimal {
        // Find ETH position
        for position in userState.assetPositions {
            if position.position.coin == Self.COIN {
                return position.position.szi
            }
        }
        return 0
    }
    
    private func placeOrders(
        currentPosition: Decimal,
        bidPrice: Decimal,
        askPrice: Decimal,
        openOrders: [OpenOrder]
    ) async throws {
        let orderSize: Decimal = 0.1 // Fixed order size
        
        // Cancel existing orders
        for order in openOrders where order.coin == Self.COIN {
            _ = try await client.cancelOrder(coin: Self.COIN, oid: order.oid)
        }
        
        // Place new orders based on position
        if currentPosition < Self.MAX_POSITION {
            // Can place bid order
            _ = try await client.limitBuy(
                coin: Self.COIN,
                sz: orderSize,
                px: bidPrice,
                reduceOnly: false
            )
            print("✅ Placed bid order: \(orderSize) \(Self.COIN) @ $\(bidPrice)")
        }
        
        if currentPosition > -Self.MAX_POSITION {
            // Can place ask order
            _ = try await client.limitSell(
                coin: Self.COIN,
                sz: orderSize,
                px: askPrice,
                reduceOnly: false
            )
            print("✅ Placed ask order: \(orderSize) \(Self.COIN) @ $\(askPrice)")
        }
    }
}

// MARK: - Error Types
public enum MarketMakingError: Error, LocalizedError {
    case invalidPrice
    case insufficientBalance
    case orderFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidPrice:
            return "Invalid price data received"
        case .insufficientBalance:
            return "Insufficient balance for order"
        case .orderFailed:
            return "Order placement failed"
        }
    }
}

// MARK: - Main Function
@main
struct MarketMakingExampleMain {
    static func main() async throws {
        // Simple setup for demo
        let userAddress = "0x1234567890123456789012345678901234567890"
        let client = try HyperliquidClient(
            privateKeyHex: "your_private_key_here",
            environment: .testnet
        )
        
        let strategy = MarketMakingExample(client: client, userAddress: userAddress)
        try await strategy.run()
    }
}

