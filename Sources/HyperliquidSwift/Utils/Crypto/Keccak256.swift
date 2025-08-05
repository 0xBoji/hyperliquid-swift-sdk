import Foundation

/// Keccak256 hashing implementation
public struct Keccak256 {
    
    /// Hash data using Keccak256
    public static func hash(data: Data) throws -> Data {
        return try keccak256(data)
    }
    
    /// Hash string using Keccak256
    public static func hash(string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw HyperliquidError.invalidInput("Failed to convert string to data")
        }
        return try hash(data: data)
    }
}

// MARK: - Keccak256 Implementation

private func keccak256(_ data: Data) throws -> Data {
    let digestLength = 32
    var hash = Data(count: digestLength)
    
    data.withUnsafeBytes { dataBytes in
        hash.withUnsafeMutableBytes { hashBytes in
            keccak(
                hashBytes.bindMemory(to: UInt8.self).baseAddress!,
                digestLength,
                dataBytes.bindMemory(to: UInt8.self).baseAddress!,
                data.count
            )
        }
    }
    
    return hash
}

// MARK: - Keccak Implementation

private func keccak(_ output: UnsafeMutablePointer<UInt8>, _ outputLength: Int, _ input: UnsafePointer<UInt8>, _ inputLength: Int) {
    let _ = 24 // keccakRounds
    let keccakLaneSize = 8
    let keccakStateSize = 25
    
    var state = Array<UInt64>(repeating: 0, count: keccakStateSize)
    let rate = 200 - 2 * outputLength
    
    // Absorb phase
    var inputOffset = 0
    while inputOffset < inputLength {
        let blockSize = min(rate, inputLength - inputOffset)
        
        for i in 0..<blockSize {
            let laneIndex = i / keccakLaneSize
            let byteIndex = i % keccakLaneSize
            let byte = input[inputOffset + i]
            state[laneIndex] ^= UInt64(byte) << (8 * byteIndex)
        }
        
        if blockSize == rate {
            keccakF1600(&state)
        }
        
        inputOffset += blockSize
    }
    
    // Padding
    let paddingOffset = inputLength % rate
    let laneIndex = paddingOffset / keccakLaneSize
    let byteIndex = paddingOffset % keccakLaneSize
    state[laneIndex] ^= UInt64(0x01) << (8 * byteIndex)
    
    let lastLaneIndex = (rate - 1) / keccakLaneSize
    let lastByteIndex = (rate - 1) % keccakLaneSize
    state[lastLaneIndex] ^= UInt64(0x80) << (8 * lastByteIndex)
    
    keccakF1600(&state)
    
    // Squeeze phase
    var outputOffset = 0
    while outputOffset < outputLength {
        let blockSize = min(rate, outputLength - outputOffset)
        
        for i in 0..<blockSize {
            let laneIndex = i / keccakLaneSize
            let byteIndex = i % keccakLaneSize
            output[outputOffset + i] = UInt8((state[laneIndex] >> (8 * byteIndex)) & 0xFF)
        }
        
        outputOffset += blockSize
        
        if outputOffset < outputLength {
            keccakF1600(&state)
        }
    }
}

private func keccakF1600(_ state: inout [UInt64]) {
    let roundConstants: [UInt64] = [
        0x0000000000000001, 0x0000000000008082, 0x800000000000808a, 0x8000000080008000,
        0x000000000000808b, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
        0x000000000000008a, 0x0000000000000088, 0x0000000080008009, 0x8000000000008003,
        0x8000000000008002, 0x8000000000000080, 0x000000000000800a, 0x800000008000000a,
        0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
        0x0000000000008082, 0x800000000000808a, 0x800000000000808a, 0x8000000080008000
    ]
    
    let rhoOffsets: [Int] = [
        0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14
    ]
    
    for round in 0..<24 {
        // Theta step
        var c = Array<UInt64>(repeating: 0, count: 5)
        for x in 0..<5 {
            c[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20]
        }
        
        var d = Array<UInt64>(repeating: 0, count: 5)
        for x in 0..<5 {
            d[x] = c[(x + 4) % 5] ^ rotateLeft(c[(x + 1) % 5], 1)
        }
        
        for x in 0..<5 {
            for y in 0..<5 {
                state[y * 5 + x] ^= d[x]
            }
        }
        
        // Rho and Pi steps
        var current = state[1]
        for i in 0..<24 {
            let next = (i + 1) % 24
            let temp = state[piIndices[next]]
            state[piIndices[next]] = rotateLeft(current, rhoOffsets[next])
            current = temp
        }
        
        // Chi step
        for y in 0..<5 {
            let t = Array(state[y * 5..<(y + 1) * 5])
            for x in 0..<5 {
                state[y * 5 + x] = t[x] ^ ((~t[(x + 1) % 5]) & t[(x + 2) % 5])
            }
        }
        
        // Iota step
        state[0] ^= roundConstants[round]
    }
}

private let piIndices: [Int] = [
    0, 6, 12, 18, 24, 3, 9, 10, 16, 22, 1, 7, 13, 19, 20, 4, 5, 11, 17, 23, 2, 8, 14, 15, 21
]

private func rotateLeft(_ value: UInt64, _ amount: Int) -> UInt64 {
    return (value << amount) | (value >> (64 - amount))
}
