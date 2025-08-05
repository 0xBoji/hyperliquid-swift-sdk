import Foundation
import libsecp256k1

/// Private key for cryptographic operations
public struct PrivateKey: Sendable {
    
    // MARK: - Properties
    
    private let keyData: Data
    
    // MARK: - Initialization
    
    /// Initialize from hex string
    public init(hex: String) throws {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        
        guard cleanHex.count == Constants.Crypto.privateKeyHexLength else {
            throw HyperliquidError.invalidPrivateKey("Private key must be \(Constants.Crypto.privateKeyLength) bytes (\(Constants.Crypto.privateKeyHexLength) hex characters)")
        }
        
        guard let data = Data(hex: cleanHex) else {
            throw HyperliquidError.invalidPrivateKey("Invalid hex string")
        }
        
        self.keyData = data
    }
    
    /// Initialize from raw data
    public init(data: Data) throws {
        guard data.count == Constants.Crypto.privateKeyLength else {
            throw HyperliquidError.invalidPrivateKey("Private key must be \(Constants.Crypto.privateKeyLength) bytes")
        }
        
        self.keyData = data
    }
    
    // MARK: - Public Methods
    
    /// Get the wallet address derived from this private key
    public var walletAddress: String {
        do {
            let publicKey = try getPublicKey()
            return try deriveAddress(from: publicKey)
        } catch {
            return ""
        }
    }
    
    /// Get the public key
    public func getPublicKey() throws -> Data {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!
        defer { secp256k1_context_destroy(context) }
        
        var publicKey = secp256k1_pubkey()
        let result = keyData.withUnsafeBytes { keyBytes in
            secp256k1_ec_pubkey_create(context, &publicKey, keyBytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == 1 else {
            throw HyperliquidError.invalidPrivateKey("Failed to generate public key")
        }
        
        var serializedPubKey = Data(count: 65)
        var outputLen = 65
        
        let serializeResult = serializedPubKey.withUnsafeMutableBytes { pubKeyBytes in
            secp256k1_ec_pubkey_serialize(
                context,
                pubKeyBytes.bindMemory(to: UInt8.self).baseAddress!,
                &outputLen,
                &publicKey,
                UInt32(SECP256K1_EC_UNCOMPRESSED)
            )
        }
        
        guard serializeResult == 1 else {
            throw HyperliquidError.signingFailed("Failed to serialize public key")
        }
        
        return serializedPubKey
    }
    
    /// Sign a message hash
    public func sign(messageHash: Data) throws -> Data {
        guard messageHash.count == 32 else {
            throw HyperliquidError.signingFailed("Message hash must be 32 bytes")
        }

        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!
        defer { secp256k1_context_destroy(context) }

        var recoverableSignature = secp256k1_ecdsa_recoverable_signature()

        // Use recoverable signature for Ethereum compatibility
        let result = keyData.withUnsafeBytes { keyBytes in
            messageHash.withUnsafeBytes { hashBytes in
                secp256k1_ecdsa_sign_recoverable(
                    context,
                    &recoverableSignature,
                    hashBytes.bindMemory(to: UInt8.self).baseAddress!,
                    keyBytes.bindMemory(to: UInt8.self).baseAddress!,
                    nil,
                    nil
                )
            }
        }

        guard result == 1 else {
            throw HyperliquidError.signingFailed("Failed to sign message")
        }

        // Serialize recoverable signature to compact format with recovery ID
        var compactSignature = Data(count: 64)
        var recoveryId: Int32 = 0

        let serializeResult = compactSignature.withUnsafeMutableBytes { sigBytes in
            secp256k1_ecdsa_recoverable_signature_serialize_compact(
                context,
                sigBytes.bindMemory(to: UInt8.self).baseAddress!,
                &recoveryId,
                &recoverableSignature
            )
        }

        guard serializeResult == 1 else {
            throw HyperliquidError.signingFailed("Failed to serialize signature")
        }

        // Append recovery ID (v = 27 + recoveryId for Ethereum)
        var ethereumSignature = compactSignature
        ethereumSignature.append(UInt8(27 + recoveryId))

        return ethereumSignature
    }
    
    // MARK: - Private Methods

    private func deriveAddress(from publicKey: Data) throws -> String {
        // Remove the first byte (0x04) from uncompressed public key
        let publicKeyWithoutPrefix = publicKey.dropFirst()
        
        // Hash the public key with Keccak256
        let hash = try Keccak256.hash(data: publicKeyWithoutPrefix)
        
        // Take the last 20 bytes and convert to hex address
        let addressBytes = hash.suffix(20)
        let address = "0x" + addressBytes.map { String(format: "%02x", $0) }.joined()
        
        return address
    }
}

// MARK: - Data Extension

extension Data {
    init?(hex: String) {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
        guard cleanHex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = cleanHex.startIndex
        
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            let byteString = String(cleanHex[index..<nextIndex])
            
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            
            index = nextIndex
        }
        
        self = data
    }
}
