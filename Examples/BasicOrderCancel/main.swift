import Foundation
import HyperliquidSwiftSDK

struct Config: Decodable { let secret_key: String }

func loadSecret() -> String {
	let url = URL(fileURLWithPath: "Examples/config.json")
	if let data = try? Data(contentsOf: url), let cfg = try? JSONDecoder().decode(Config.self, from: data) {
		return cfg.secret_key
	}
	return ""
}

@main
struct BasicOrderCancel {
	static func main() async {
		let sk = loadSecret()
		guard !sk.isEmpty else { print("missing secret_key in Examples/config.json"); exit(1) }
		let base = InfoClient.defaultURL(for: .testnet)
		do {
			let exch = try ExchangeClient(baseURL: base, privateKeyHex: sk)
			
			// Debug: Check account address derivation
			
			// Get account address from the signer
			let accountAddress = try exch.getAccountAddress()
			print("Account address from private key:", accountAddress)
			
			// Test signature recovery to verify address consistency
			let testMessage = "test message".data(using: .utf8)!
			let testHash = keccak256(testMessage)
			let testSignature = try exch.evmSigner.signTypedData(testHash)
			let recoveredAddress = try exch.evmSigner.getAddressFromSignature(testSignature, messageHash: testHash)
			print("Recovered address from signature:", recoveredAddress)
			print("Addresses match:", accountAddress == recoveredAddress)
			
			// Try to cancel an existing order from BasicPlaceOnlyOrder
			// Use the order ID from the previous run: 39125151811
			let coin = "ETH"
			let existingOid: Int64 = 39125151811
			
			print("Attempting to cancel existing order with oid:", existingOid)
			print("Account address:", try exch.getAccountAddress())
			
			let cancelRes = try await exch.cancel(coin: coin, oid: existingOid)
			print("Cancel result:", cancelRes)
			
		} catch {
			print("Error:", error)
			if let httpError = error as? HTTPError {
				print("HTTP Error details:", httpError.localizedDescription)
			}
			exit(1)
		}
	}
}