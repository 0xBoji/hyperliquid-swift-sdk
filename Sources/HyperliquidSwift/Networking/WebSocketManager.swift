import Foundation

/// WebSocket manager for real-time data streaming
public actor WebSocketManager {
    
    // MARK: - Properties
    
    private let url: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 5
    private let session: URLSession
    
    // Subscription management
    private var subscriptions: [String: (WebSocketMessage) -> Void] = [:]
    private var activeSubscriptions: Set<String> = []
    
    // Heartbeat
    private var heartbeatTask: Task<Void, Never>?
    private let heartbeatInterval: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    public init(url: URL) {
        self.url = url
        self.session = URLSession(configuration: .default)
    }
    
    // MARK: - Connection Management
    
    /// Connect to the WebSocket
    public func connect() async throws {
        guard !isConnected else {
            return
        }
        
        // Create WebSocket task
        webSocketTask = session.webSocketTask(with: url)
        
        // Start the connection
        webSocketTask?.resume()
        isConnected = true
        
        // Start receiving messages
        startReceiving()
        
        // Start heartbeat
        startHeartbeat()
        
        reconnectionAttempts = 0
    }
    
    /// Disconnect from the WebSocket
    public func disconnect() async {
        isConnected = false
        
        // Cancel heartbeat
        heartbeatTask?.cancel()
        heartbeatTask = nil
        
        // Close WebSocket
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        // Clear subscriptions
        subscriptions.removeAll()
        activeSubscriptions.removeAll()
    }
    
    // MARK: - Subscription Management
    
    /// Subscribe to a WebSocket channel
    public func subscribe(to subscription: String, handler: @escaping (WebSocketMessage) -> Void) async throws {
        subscriptions[subscription] = handler
        activeSubscriptions.insert(subscription)
        
        if isConnected {
            try await sendSubscription(subscription)
        }
    }
    
    /// Unsubscribe from a WebSocket channel
    public func unsubscribe(from subscription: String) async throws {
        subscriptions.removeValue(forKey: subscription)
        activeSubscriptions.remove(subscription)
        
        if isConnected {
            try await sendUnsubscription(subscription)
        }
    }
    
    // MARK: - Private Methods
    
    private func startReceiving() {
        guard let webSocketTask = webSocketTask else { return }
        
        Task {
            do {
                let message = try await webSocketTask.receive()
                await handleMessage(message)
                
                // Continue receiving if still connected
                if isConnected {
                    startReceiving()
                }
            } catch {
                await handleConnectionError(error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            await processTextMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                await processTextMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func processTextMessage(_ text: String) async {
        do {
            let data = text.data(using: .utf8) ?? Data()
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            
            // Route message to appropriate handler
            for (subscription, handler) in subscriptions {
                if message.channel == subscription {
                    handler(message)
                }
            }
        } catch {
            // Log parsing error
        }
    }
    
    private func handleConnectionError(_ error: Error) async {
        isConnected = false
        
        // Attempt reconnection if within limits
        if reconnectionAttempts < maxReconnectionAttempts {
            reconnectionAttempts += 1
            
            // Wait before reconnecting
            try? await Task.sleep(nanoseconds: UInt64(2_000_000_000 * reconnectionAttempts))
            
            try? await connect()
            
            // Resubscribe to active subscriptions
            for subscription in activeSubscriptions {
                try? await sendSubscription(subscription)
            }
        }
    }
    
    private func sendSubscription(_ subscription: String) async throws {
        let message = ["method": "subscribe", "subscription": subscription]
        try await sendMessage(message)
    }
    
    private func sendUnsubscription(_ subscription: String) async throws {
        let message = ["method": "unsubscribe", "subscription": subscription]
        try await sendMessage(message)
    }
    
    private func sendMessage(_ message: [String: Any]) async throws {
        guard let webSocketTask = webSocketTask, isConnected else {
            throw HyperliquidError.webSocketError("Not connected")
        }
        
        let data = try JSONSerialization.data(withJSONObject: message)
        let text = String(data: data, encoding: .utf8) ?? ""
        
        try await webSocketTask.send(.string(text))
    }
    
    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled && isConnected {
                try? await Task.sleep(nanoseconds: UInt64(heartbeatInterval * 1_000_000_000))
                
                if isConnected {
                    // Send ping message manually
                    try? await sendMessage(["type": "ping"])
                }
            }
        }
    }
}

// MARK: - WebSocket Message

/// WebSocket message structure
public struct WebSocketMessage: Codable, Sendable {
    public let channel: String
    public let data: WebSocketData
    
    public init(channel: String, data: WebSocketData) {
        self.channel = channel
        self.data = data
    }
}

/// WebSocket data wrapper
public enum WebSocketData: Codable, Sendable {
    case allMids([String: String])
    case l2Book(L2BookData)
    case trades([TradeData])
    case userEvents([UserEventData])
    case userFills([Fill])
    case unknown
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let allMids = try? container.decode([String: String].self) {
            self = .allMids(allMids)
        } else if let l2Book = try? container.decode(L2BookData.self) {
            self = .l2Book(l2Book)
        } else if let trades = try? container.decode([TradeData].self) {
            self = .trades(trades)
        } else if let userEvents = try? container.decode([UserEventData].self) {
            self = .userEvents(userEvents)
        } else if let userFills = try? container.decode([Fill].self) {
            self = .userFills(userFills)
        } else {
            self = .unknown
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .allMids(let data):
            try container.encode(data)
        case .l2Book(let data):
            try container.encode(data)
        case .trades(let data):
            try container.encode(data)
        case .userEvents(let data):
            try container.encode(data)
        case .userFills(let data):
            try container.encode(data)
        case .unknown:
            try container.encode("unknown")
        }
    }
}

// MARK: - Supporting Types

public struct L2BookData: Codable, Sendable {
    public let coin: String
    public let levels: [[L2Level]]
    
    public init(coin: String, levels: [[L2Level]]) {
        self.coin = coin
        self.levels = levels
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.coin = try container.decode(String.self, forKey: .coin)
        
        // Handle levels as array of arrays, with flexible parsing
        let levelsArray = try container.decode([[[String: Any]]].self, forKey: .levels)
        var parsedLevels: [[L2Level]] = []
        
        for levelGroup in levelsArray {
            var parsedGroup: [L2Level] = []
            for levelDict in levelGroup {
                let px: Decimal
                let sz: Decimal
                let n: Int
                
                // Parse px
                if let pxString = levelDict["px"] as? String {
                    px = Decimal(string: pxString) ?? Decimal(0)
                } else if let pxNumber = levelDict["px"] as? NSNumber {
                    px = Decimal(string: pxNumber.stringValue) ?? Decimal(0)
                } else {
                    px = Decimal(0)
                }
                
                // Parse sz
                if let szString = levelDict["sz"] as? String {
                    sz = Decimal(string: szString) ?? Decimal(0)
                } else if let szNumber = levelDict["sz"] as? NSNumber {
                    sz = Decimal(string: szNumber.stringValue) ?? Decimal(0)
                } else {
                    sz = Decimal(0)
                }
                
                // Parse n
                n = levelDict["n"] as? Int ?? 0
                
                parsedGroup.append(L2Level(px: px, sz: sz, n: n))
            }
            parsedLevels.append(parsedGroup)
        }
        
        self.levels = parsedLevels
    }
    
    private enum CodingKeys: String, CodingKey {
        case coin, levels
    }
}

public struct L2Level: Codable, Sendable {
    public let px: Decimal
    public let sz: Decimal
    public let n: Int
    
    public init(px: Decimal, sz: Decimal, n: Int) {
        self.px = px
        self.sz = sz
        self.n = n
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle px as either String or Decimal
        if let pxString = try? container.decode(String.self, forKey: .px) {
            self.px = Decimal(string: pxString) ?? Decimal(0)
        } else {
            self.px = try container.decode(Decimal.self, forKey: .px)
        }
        
        // Handle sz as either String or Decimal
        if let szString = try? container.decode(String.self, forKey: .sz) {
            self.sz = Decimal(string: szString) ?? Decimal(0)
        } else {
            self.sz = try container.decode(Decimal.self, forKey: .sz)
        }
        
        self.n = try container.decode(Int.self, forKey: .n)
    }
    
    private enum CodingKeys: String, CodingKey {
        case px, sz, n
    }
}

public struct TradeData: Codable, Sendable {
    public let coin: String
    public let side: Side
    public let px: Decimal
    public let sz: Decimal
    public let time: Int64
    
    public init(coin: String, side: Side, px: Decimal, sz: Decimal, time: Int64) {
        self.coin = coin
        self.side = side
        self.px = px
        self.sz = sz
        self.time = time
    }
}

public struct UserEventData: Codable, Sendable {
    public let fills: [Fill]?
    public let liquidation: Bool?
    
    public init(fills: [Fill]? = nil, liquidation: Bool? = nil) {
        self.fills = fills
        self.liquidation = liquidation
    }
}
