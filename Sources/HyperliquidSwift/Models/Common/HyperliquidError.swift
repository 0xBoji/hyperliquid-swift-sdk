import Foundation

/// Comprehensive error types for the Hyperliquid SDK
public enum HyperliquidError: Error, LocalizedError, Sendable {
    
    // MARK: - Network Errors
    case networkError(String)
    case invalidURL(String)
    case requestFailed(statusCode: Int, message: String)
    case responseParsingFailed(String)
    case timeout(String)
    
    // MARK: - Authentication Errors
    case invalidPrivateKey(String)
    case signingFailed(String)
    case authenticationRequired(String)
    case clientNotInitialized
    
    // MARK: - Trading Errors
    case invalidOrder(String)
    case orderNotFound(String)
    case positionNotFound(String)
    case insufficientBalance(String)
    case marketClosed(String)
    
    // MARK: - WebSocket Errors
    case webSocketError(String)
    case subscriptionFailed(String)
    case connectionLost(String)
    
    // MARK: - Validation Errors
    case invalidInput(String)
    case missingRequiredField(String)
    case invalidFormat(String)
    
    // MARK: - API Errors
    case apiError(code: String, message: String)
    case rateLimitExceeded(String)
    case serverError(String)
    
    // MARK: - Configuration Errors
    case configurationError(String)
    case unsupportedOperation(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .requestFailed(let statusCode, let message):
            return "Request failed with status \(statusCode): \(message)"
        case .responseParsingFailed(let message):
            return "Failed to parse response: \(message)"
        case .timeout(let message):
            return "Request timeout: \(message)"
        case .invalidPrivateKey(let message):
            return "Invalid private key: \(message)"
        case .signingFailed(let message):
            return "Signing failed: \(message)"
        case .authenticationRequired(let message):
            return "Authentication required: \(message)"
        case .clientNotInitialized:
            return "Client not initialized for trading operations"
        case .invalidOrder(let message):
            return "Invalid order: \(message)"
        case .orderNotFound(let message):
            return "Order not found: \(message)"
        case .positionNotFound(let message):
            return "Position not found: \(message)"
        case .insufficientBalance(let message):
            return "Insufficient balance: \(message)"
        case .marketClosed(let message):
            return "Market closed: \(message)"
        case .webSocketError(let message):
            return "WebSocket error: \(message)"
        case .subscriptionFailed(let message):
            return "Subscription failed: \(message)"
        case .connectionLost(let message):
            return "Connection lost: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .missingRequiredField(let message):
            return "Missing required field: \(message)"
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .apiError(let code, let message):
            return "API error [\(code)]: \(message)"
        case .rateLimitExceeded(let message):
            return "Rate limit exceeded: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .unsupportedOperation(let message):
            return "Unsupported operation: \(message)"
        }
    }
}

// MARK: - Error Categories
extension HyperliquidError {
    
    /// Whether this error is recoverable
    public var isRecoverable: Bool {
        switch self {
        case .networkError, .timeout, .connectionLost, .rateLimitExceeded, .serverError:
            return true
        default:
            return false
        }
    }
    
    /// Whether this error should trigger a retry
    public var shouldRetry: Bool {
        switch self {
        case .networkError, .timeout, .serverError:
            return true
        case .rateLimitExceeded:
            return true
        default:
            return false
        }
    }
}
