import Foundation

/// Wrapper for JSON responses that can't be strongly typed
public struct JSONResponse: Codable, Sendable {
    private let data: Data
    
    public init(from decoder: Decoder) throws {
        // Store the raw JSON data
        let container = try decoder.singleValueContainer()
        let jsonObject = try container.decode(RawJSON.self)
        self.data = try JSONSerialization.data(withJSONObject: jsonObject.value)
    }
    
    public func encode(to encoder: Encoder) throws {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        var container = encoder.singleValueContainer()
        try container.encode(RawJSON(value: jsonObject))
    }
    
    /// Convert to dictionary
    public var dictionary: [String: Any] {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            return jsonObject as? [String: Any] ?? [:]
        } catch {
            return [:]
        }
    }
    
    /// Convert to array
    public var array: [Any] {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            return jsonObject as? [Any] ?? []
        } catch {
            return []
        }
    }
}

// MARK: - Helper for raw JSON handling

private struct RawJSON: Codable {
    let value: Any
    
    init(value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([RawJSON].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: RawJSON].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode JSON value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { RawJSON(value: $0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { RawJSON(value: $0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Cannot encode JSON value")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
