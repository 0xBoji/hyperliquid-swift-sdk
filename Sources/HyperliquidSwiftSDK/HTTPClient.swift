import Foundation

public protocol NetworkTransport {
    func post<T: Decodable>(baseURL: URL, path: String, body: Encodable, timeout: TimeInterval?) async throws -> T
    func postRaw(baseURL: URL, path: String, body: Encodable, timeout: TimeInterval?) async throws -> Data
    func postJSON(baseURL: URL, path: String, jsonBody: Any, timeout: TimeInterval?) async throws -> Data
}

public final class URLSessionTransport: NetworkTransport {
    private let session: URLSession

    public init(configuration: URLSessionConfiguration = .ephemeral) {
        self.session = URLSession(configuration: configuration)
    }

    public func post<T: Decodable>(baseURL: URL, path: String, body: Encodable, timeout: TimeInterval?) async throws -> T {
        var url = baseURL
        url.appendPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let timeout { request.timeoutInterval = timeout }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        request.httpBody = try encoder.encode(AnyEncodable(body))

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPError.statusCode(http.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try decoder.decode(T.self, from: data)
    }

    public func postRaw(baseURL: URL, path: String, body: Encodable, timeout: TimeInterval?) async throws -> Data {
        var url = baseURL
        url.appendPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let timeout { request.timeoutInterval = timeout }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        request.httpBody = try encoder.encode(AnyEncodable(body))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else { throw HTTPError.statusCode(http.statusCode, data: data) }
        return data
    }

    public func postJSON(baseURL: URL, path: String, jsonBody: Any, timeout: TimeInterval?) async throws -> Data {
        var url = baseURL
        url.appendPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let timeout { request.timeoutInterval = timeout }

        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else { throw HTTPError.statusCode(http.statusCode, data: data) }
        return data
    }
}

public enum HTTPError: Error, LocalizedError {
    case statusCode(Int, data: Data)

    public var errorDescription: String? {
        switch self {
        case .statusCode(let code, let data):
            let text = String(data: data, encoding: .utf8) ?? "<no body>"
            return "HTTP error: \(code) body=\(text)"
        }
    }
}

struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encodeFunc = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}


