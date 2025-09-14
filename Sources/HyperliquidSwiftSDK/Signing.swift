import Foundation
import CryptoSwift
import libsecp256k1

public struct EcdsaSignature: Codable { public let r: String; public let s: String; public let v: UInt8 }

public enum SigningError: Error { case invalidKey; case signFailed }

public final class EvmSigner {
    private let privkey: Data
    private let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!

    public init(privateKeyHex: String) throws {
        let hex = privateKeyHex.hasPrefix("0x") ? String(privateKeyHex.dropFirst(2)) : privateKeyHex
        guard let key = Data(hex: hex), key.count == 32 else { throw SigningError.invalidKey }
        self.privkey = key
    }

    public func signTypedData(_ digest32: Data) throws -> EcdsaSignature {
        var msg = digest32
        guard msg.count == 32 else { throw SigningError.signFailed }
        var sig = secp256k1_ecdsa_recoverable_signature()
        var recid: Int32 = 0
        let ok = self.privkey.withUnsafeBytes { keyPtr -> Bool in
            msg.withUnsafeBytes { msgPtr in
                return secp256k1_ecdsa_sign_recoverable(self.ctx, &sig, msgPtr.bindMemory(to: UInt8.self).baseAddress!, keyPtr.bindMemory(to: UInt8.self).baseAddress!, nil, nil) == 1
            }
        }
        if !ok { throw SigningError.signFailed }
        var compact = [UInt8](repeating: 0, count: 64)
        secp256k1_ecdsa_recoverable_signature_serialize_compact(ctx, &compact, &recid, &sig)
        let r = Data(compact[0..<32])
        let s = Data(compact[32..<64])
        let v: UInt8 = 27 + UInt8(recid)
        return .init(r: "0x" + r.toHexString(), s: "0x" + s.toHexString(), v: v)
    }
}

// MARK: - Hashing helpers

public func keccak256(_ data: Data) -> Data {
    return Data(data.sha3(.keccak256))
}

// MARK: - EIP-712 minimal encoder for Agent
// domain: {name: Exchange, version: 1, chainId: 1337, verifyingContract: 0x0}
// primaryType: Agent { source: string, connectionId: bytes32 }
public func eip712HashAgent(source: String, connectionId: Data) -> Data {
    // Per EIP-712: keccak("\x19\x01" || domainSeparator || hashStruct(message))
    let domainTypeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)".data(using: .utf8)!)
    let nameHash = keccak256("Exchange".data(using: .utf8)!)
    let versionHash = keccak256("1".data(using: .utf8)!)
    var chainId = Data(count: 32)
    let chainIdVal: UInt64 = 1337
    chainId.replaceSubrange(24..<32, with: withUnsafeBytes(of: chainIdVal.bigEndian, Array.init))
    let zeroAddress = Data(count: 32)
    var domain = Data()
    domain.append(domainTypeHash)
    domain.append(nameHash)
    domain.append(versionHash)
    domain.append(chainId)
    domain.append(zeroAddress)
    let domainSeparator = keccak256(domain)

    let agentTypeHash = keccak256("Agent(string source,bytes32 connectionId)".data(using: .utf8)!)
    let sourceHash = keccak256(source.data(using: .utf8)!)
    var msg = Data()
    msg.append(agentTypeHash)
    msg.append(sourceHash)
    var connPadded = Data(count: 32)
    connPadded.replaceSubrange(0..<min(32, connectionId.count), with: connectionId.prefix(32))
    msg.append(connPadded)
    let messageHash = keccak256(msg)

    var prefix = Data([0x19, 0x01])
    prefix.append(domainSeparator)
    prefix.append(messageHash)
    return keccak256(prefix)
}

// Minimal MsgPack encoder for the subset we need
public struct OrderedMap {
    public let pairs: [(String, Any)]
    public init(_ pairs: [(String, Any)]) { self.pairs = pairs }
}

public enum MsgPack {
    public static func encode(_ value: Any) -> Data {
        var buffer = Data()
        encodeValue(value, into: &buffer)
        return buffer
    }

    private static func encodeValue(_ value: Any, into buffer: inout Data) {
        switch value {
        case let ordered as OrderedMap:
            let count = ordered.pairs.count
            encodeMapHeader(count, into: &buffer)
            for (k, v) in ordered.pairs {
                encodeString(k, into: &buffer)
                encodeValue(v, into: &buffer)
            }
        case let dict as [String: Any]:
            let count = dict.count
            encodeMapHeader(count, into: &buffer)
            // Swift dict order is undefined; sort by key for determinism
            for (k, v) in dict.sorted(by: { $0.key < $1.key }) {
                encodeString(k, into: &buffer)
                encodeValue(v, into: &buffer)
            }
        case let arr as [Any]:
            let count = arr.count
            encodeArrayHeader(count, into: &buffer)
            for v in arr { encodeValue(v, into: &buffer) }
        case let str as String:
            encodeString(str, into: &buffer)
        case let i as Int:
            encodeInt(Int64(i), into: &buffer)
        case let i as Int64:
            encodeInt(i, into: &buffer)
        case let b as Bool:
            buffer.append(b ? 0xC3 : 0xC2)
        default:
            if let d = value as? Double {
                var bitPattern = d.bitPattern.bigEndian
                buffer.append(0xCB)
                buffer.append(contentsOf: withUnsafeBytes(of: &bitPattern) { Array($0) })
            } else if let n = value as? NSNull {
                buffer.append(0xC0)
            } else {
                // best-effort encode string
                encodeString(String(describing: value), into: &buffer)
            }
        }
    }

    private static func encodeString(_ str: String, into buffer: inout Data) {
        let bytes = Array(str.utf8)
        let count = bytes.count
        if count <= 31 {
            buffer.append(0xA0 | UInt8(count))
        } else if count <= 255 {
            buffer.append(0xD9)
            buffer.append(UInt8(count))
        } else if count <= 0xFFFF {
            buffer.append(0xDA)
            var c = UInt16(count).bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &c) { Array($0) })
        } else {
            buffer.append(0xDB)
            var c = UInt32(count).bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &c) { Array($0) })
        }
        buffer.append(contentsOf: bytes)
    }

    private static func encodeInt(_ i: Int64, into buffer: inout Data) {
        if i >= 0 && i <= 127 {
            buffer.append(UInt8(i))
        } else if i >= 0 && i <= 0xFF {
            buffer.append(0xCC)
            buffer.append(UInt8(i))
        } else if i >= 0 && i <= 0xFFFF {
            buffer.append(0xCD)
            var v = UInt16(i).bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
        } else if i >= 0 && i <= 0xFFFFFFFF {
            buffer.append(0xCE)
            var v = UInt32(i).bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
        } else {
            buffer.append(0xD3)
            var v = i.bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
        }
    }

    private static func encodeMapHeader(_ count: Int, into buffer: inout Data) {
        if count <= 15 {
            buffer.append(0x80 | UInt8(count))
        } else if count <= 0xFFFF {
            buffer.append(0xDE)
            var c = UInt16(count).bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &c) { Array($0) })
        } else {
            buffer.append(0xDF)
            var c = UInt32(count).bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &c) { Array($0) })
        }
    }

    private static func encodeArrayHeader(_ count: Int, into buffer: inout Data) {
        if count <= 15 {
            buffer.append(0x90 | UInt8(count))
        } else if count <= 0xFFFF {
            buffer.append(0xDC)
            var c = UInt16(count).bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &c) { Array($0) })
        } else {
            buffer.append(0xDD)
            var c = UInt32(count).bigEndian
            buffer.append(contentsOf: withUnsafeBytes(of: &c) { Array($0) })
        }
    }
}

extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var index = hex.startIndex
        for _ in 0..<len {
            let next = hex.index(index, offsetBy: 2)
            guard next <= hex.endIndex else { return nil }
            let bytes = hex[index..<next]
            guard let b = UInt8(bytes, radix: 16) else { return nil }
            data.append(b)
            index = next
        }
        self = data
    }
}


