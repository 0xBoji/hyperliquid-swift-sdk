import Foundation
import CryptoKit
import CryptoSwift
import secp256k1

/// Service for cryptographic operations (EIP-712 signing, hashing, etc.)
public struct CryptoService {
    
    // MARK: - EIP-712 Signing
    
    /// Sign an action using EIP-712 standard
    /// - Parameters:
    ///   - action: The action to sign
    ///   - privateKey: Private key for signing
    ///   - vaultAddress: Vault address (optional)
    ///   - timestamp: Timestamp for the action
    ///   - isMainnet: Whether this is mainnet or testnet
    /// - Returns: Hex-encoded signature
    public static func signL1Action<T: Codable>(
        action: T,
        privateKey: PrivateKey,
        vaultAddress: String? = nil,
        timestamp: Int64,
        isMainnet: Bool
    ) throws -> String {
        // Create action hash
        let actionHash = try createActionHash(
            action: action,
            vaultAddress: vaultAddress,
            timestamp: timestamp
        )
        
        // Create phantom agent
        let phantomAgent = createPhantomAgent(hash: actionHash, isMainnet: isMainnet)
        
        // Create EIP-712 payload
        let payload = createL1Payload(phantomAgent: phantomAgent)
        
        // Sign the payload
        return try signEIP712(payload: payload, privateKey: privateKey)
    }
    
    /// Create action hash for signing
    private static func createActionHash<T: Codable>(
        action: T,
        vaultAddress: String?,
        timestamp: Int64
    ) throws -> Data {
        // Encode action to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let actionData = try encoder.encode(action)
        
        // Create hash input
        var hashInput = Data()
        hashInput.append(actionData)
        
        if let vaultAddress = vaultAddress {
            hashInput.append(vaultAddress.data(using: .utf8) ?? Data())
        }
        
        hashInput.append(withUnsafeBytes(of: timestamp.bigEndian) { Data($0) })
        
        // Return Keccak256 hash
        return Data(hashInput.sha3(.keccak256))
    }
    
    /// Create phantom agent for EIP-712 signing
    private static func createPhantomAgent(hash: Data, isMainnet: Bool) -> PhantomAgent {
        let source = isMainnet ? "a" : "b"
        let connectionId = hash.prefix(16) // First 16 bytes
        
        return PhantomAgent(
            source: source,
            connectionId: connectionId.hexString
        )
    }
    
    /// Create L1 payload for EIP-712 signing
    private static func createL1Payload(phantomAgent: PhantomAgent) -> EIP712Payload {
        let domain = EIP712Domain(
            name: "HyperliquidSignTransaction",
            version: "1",
            chainId: 1337,
            verifyingContract: "0x0000000000000000000000000000000000000000"
        )
        
        let message = EIP712Message(
            source: phantomAgent.source,
            connectionId: phantomAgent.connectionId
        )
        
        return EIP712Payload(
            domain: domain,
            primaryType: "HyperliquidTransaction",
            types: EIP712Types(),
            message: message
        )
    }
    
    /// Sign EIP-712 payload
    private static func signEIP712(payload: EIP712Payload, privateKey: PrivateKey) throws -> String {
        // Encode EIP-712 payload
        let encodedData = try encodeEIP712(payload: payload)
        
        // Sign with secp256k1
        let signature = try privateKey.sign(messageHash: encodedData)

        // Return hex-encoded signature
        return "0x" + signature.hexString
    }
    
    /// Encode EIP-712 payload according to standard
    private static func encodeEIP712(payload: EIP712Payload) throws -> Data {
        // Create domain separator
        let domainSeparator = try hashStruct(
            primaryType: "EIP712Domain",
            data: payload.domain,
            types: payload.types
        )
        
        // Create message hash
        let messageHash = try hashStruct(
            primaryType: payload.primaryType,
            data: payload.message,
            types: payload.types
        )
        
        // Create final hash: keccak256("\x19\x01" + domainSeparator + messageHash)
        var finalData = Data([0x19, 0x01])
        finalData.append(domainSeparator)
        finalData.append(messageHash)
        
        return Data(finalData.sha3(.keccak256))
    }
    
    /// Hash struct according to EIP-712
    private static func hashStruct<T: Codable>(
        primaryType: String,
        data: T,
        types: EIP712Types
    ) throws -> Data {
        // This is a simplified implementation
        // In production, this should follow EIP-712 spec exactly
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let jsonData = try encoder.encode(data)
        
        return Data(jsonData.sha3(.keccak256))
    }
}

// MARK: - Supporting Types

/// Phantom agent for signing
private struct PhantomAgent {
    let source: String
    let connectionId: String
}

/// EIP-712 domain
public struct EIP712Domain: Codable {
    let name: String
    let version: String
    let chainId: Int
    let verifyingContract: String
}

/// EIP-712 message
public struct EIP712Message: Codable {
    let source: String
    let connectionId: String
}

/// EIP-712 payload
public struct EIP712Payload: Codable {
    let domain: EIP712Domain
    let primaryType: String
    let types: EIP712Types
    let message: EIP712Message
}

/// EIP-712 types definition
public struct EIP712Types: Codable {
    let EIP712Domain: [EIP712TypeDefinition]
    let HyperliquidTransaction: [EIP712TypeDefinition]
    
    init() {
        self.EIP712Domain = [
            EIP712TypeDefinition(name: "name", type: "string"),
            EIP712TypeDefinition(name: "version", type: "string"),
            EIP712TypeDefinition(name: "chainId", type: "uint256"),
            EIP712TypeDefinition(name: "verifyingContract", type: "address")
        ]
        
        self.HyperliquidTransaction = [
            EIP712TypeDefinition(name: "source", type: "string"),
            EIP712TypeDefinition(name: "connectionId", type: "string")
        ]
    }
}

/// EIP-712 type definition
public struct EIP712TypeDefinition: Codable {
    let name: String
    let type: String
}

// MARK: - Extensions

extension Data {
    /// Convert data to hex string
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

extension PrivateKey {
    /// Sign hash with secp256k1
    func sign(hash: Data) throws -> Data {
        // This is a simplified placeholder implementation
        // In production, use proper secp256k1 signing with the actual private key

        // For now, return a placeholder signature
        // TODO: Implement proper secp256k1 signing using the private key data
        let placeholderSignature = Data(repeating: 0, count: 64)
        return placeholderSignature
    }
}

/// Crypto-related errors
public enum CryptoError: Error, LocalizedError {
    case signingFailed
    case invalidPrivateKey
    case encodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .signingFailed:
            return "Failed to sign data"
        case .invalidPrivateKey:
            return "Invalid private key"
        case .encodingFailed:
            return "Failed to encode data"
        }
    }
}
