import Foundation

/// Client error for 4xx responses
public struct ClientError: Error, LocalizedError {
    public let statusCode: Int
    public let code: String?
    public let message: String
    public let headers: [String: String]?
    public let data: Any?
    
    public init(statusCode: Int, code: String?, message: String, headers: [String: String]? = nil, data: Any? = nil) {
        self.statusCode = statusCode
        self.code = code
        self.message = message
        self.headers = headers
        self.data = data
    }
    
    public var errorDescription: String? {
        return "Client Error [\(statusCode)]: \(message)"
    }
}

/// Server error for 5xx responses
public struct ServerError: Error, LocalizedError {
    public let statusCode: Int
    public let message: String
    
    public init(statusCode: Int, message: String) {
        self.statusCode = statusCode
        self.message = message
    }
    
    public var errorDescription: String? {
        return "Server Error [\(statusCode)]: \(message)"
    }
}

/// Network error for connection issues
public struct NetworkError: Error, LocalizedError {
    public let message: String
    public let underlyingError: Error?
    
    public init(message: String, underlyingError: Error? = nil) {
        self.message = message
        self.underlyingError = underlyingError
    }
    
    public var errorDescription: String? {
        return "Network Error: \(message)"
    }
}
