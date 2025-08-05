import Foundation

/// Input validation utilities
public enum Validation {
    
    /// Validate private key format
    public static func validatePrivateKey(_ key: String) throws {
        let cleanKey = key.hasPrefix("0x") ? String(key.dropFirst(2)) : key
        
        guard cleanKey.count == Constants.Crypto.privateKeyHexLength else {
            throw HyperliquidError.invalidPrivateKey("Invalid private key length")
        }
        
        guard cleanKey.allSatisfy({ $0.isHexDigit }) else {
            throw HyperliquidError.invalidPrivateKey("Invalid hex characters")
        }
        
        guard cleanKey != String(repeating: "0", count: Constants.Crypto.privateKeyHexLength) else {
            throw HyperliquidError.invalidPrivateKey("Private key cannot be all zeros")
        }
    }
    
    /// Validate wallet address format
    public static func validateAddress(_ address: String) throws {
        guard address.hasPrefix("0x") else {
            throw HyperliquidError.invalidInput("Address must start with 0x")
        }
        
        let cleanAddress = String(address.dropFirst(2))
        guard cleanAddress.count == Constants.Crypto.addressLength * 2 else {
            throw HyperliquidError.invalidInput("Invalid address length")
        }
        
        guard cleanAddress.allSatisfy({ $0.isHexDigit }) else {
            throw HyperliquidError.invalidInput("Invalid address format")
        }
    }
    
    /// Validate order size
    public static func validateOrderSize(_ size: Decimal) throws {
        guard size > 0 else {
            throw HyperliquidError.invalidOrder("Order size must be positive")
        }
        
        guard size >= Constants.Trading.minOrderSize else {
            throw HyperliquidError.invalidOrder("Order size too small")
        }
        
        guard size <= Constants.Trading.maxOrderSize else {
            throw HyperliquidError.invalidOrder("Order size too large")
        }
    }
    
    /// Validate asset symbol
    public static func validateAssetSymbol(_ symbol: String) throws {
        guard !symbol.isEmpty else {
            throw HyperliquidError.invalidInput("Asset symbol cannot be empty")
        }
        
        guard symbol.count <= 20 else {
            throw HyperliquidError.invalidInput("Asset symbol too long")
        }
    }
}

// MARK: - Character Extension

extension Character {
    var isHexDigit: Bool {
        return self.isNumber || ("a"..."f").contains(self.lowercased().first ?? Character(""))
    }
}
