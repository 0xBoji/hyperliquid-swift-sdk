import Foundation

/// HTTP client for making requests to Hyperliquid API
public actor HTTPClient {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL: URL
    private let environment: HyperliquidEnvironment
    
    // MARK: - Configuration
    
    public struct Configuration {
        public let baseURL: String
        public let timeout: TimeInterval
        public let retryCount: Int
        public let retryDelay: TimeInterval
        
        public init(
            baseURL: String,
            timeout: TimeInterval = Constants.Network.timeout,
            retryCount: Int = Constants.Network.retryCount,
            retryDelay: TimeInterval = Constants.Network.retryDelay
        ) {
            self.baseURL = baseURL
            self.timeout = timeout
            self.retryCount = retryCount
            self.retryDelay = retryDelay
        }
    }
    
    // MARK: - Initialization
    
    public init(configuration: Configuration) throws {
        guard let url = URL(string: configuration.baseURL) else {
            throw HyperliquidError.invalidURL(configuration.baseURL)
        }
        
        self.baseURL = url
        self.environment = configuration.baseURL.contains("testnet") ? .testnet : .mainnet
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2
        
        self.session = URLSession(configuration: sessionConfig)
    }
    
    // MARK: - Public Methods
    
    /// Make a POST request and decode the response
    public func postAndDecode<T: Codable>(
        path: String,
        payload: [String: Any],
        responseType: T.Type,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.Headers.jsonValue, forHTTPHeaderField: Constants.Headers.contentType)
        request.setValue(Constants.userAgent, forHTTPHeaderField: Constants.Headers.userAgent)
        
        // Add additional headers
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw HyperliquidError.requestFailed(statusCode: 0, message: "Failed to serialize request body: \(error)")
        }
        
        // Make request with retry logic
        return try await performRequestWithRetry(request: request, responseType: responseType)
    }
    
    /// Make a GET request and decode the response
    public func getAndDecode<T: Codable>(
        path: String,
        queryParameters: [String: String] = [:],
        responseType: T.Type,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        
        if !queryParameters.isEmpty {
            urlComponents?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else {
            throw HyperliquidError.invalidURL(path)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Constants.Headers.jsonValue, forHTTPHeaderField: Constants.Headers.accept)
        request.setValue(Constants.userAgent, forHTTPHeaderField: Constants.Headers.userAgent)
        
        // Add additional headers
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Make request with retry logic
        return try await performRequestWithRetry(request: request, responseType: responseType)
    }
    
    // MARK: - Private Methods
    
    private func performRequestWithRetry<T: Codable>(
        request: URLRequest,
        responseType: T.Type,
        retryCount: Int = 3
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<retryCount {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HyperliquidError.networkError("Invalid response type")
                }
                
                // Check status code
                guard 200...299 ~= httpResponse.statusCode else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw HyperliquidError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage)
                }
                
                // Decode response
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .millisecondsSince1970
                    return try decoder.decode(responseType, from: data)
                } catch {
                    throw HyperliquidError.responseParsingFailed("Failed to decode response: \(error)")
                }
                
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                if case HyperliquidError.requestFailed(let statusCode, _) = error,
                   400...499 ~= statusCode {
                    throw error
                }
                
                // Wait before retry (except on last attempt)
                if attempt < retryCount - 1 {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * (attempt + 1))) // Exponential backoff
                }
            }
        }
        
        throw lastError ?? HyperliquidError.networkError("Request failed after \(retryCount) attempts")
    }
}
