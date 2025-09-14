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
			
			// Place a new order to test with same account
			let coin = "ETH"
			let isBuy = true
			let size = 0.01
			let limitPx = 1000.0  // Very low price to ensure it stays resting
			
			print("Placing new order with same account...")
			let orderRes = try await exch.order(
				coin: coin,
				isBuy: isBuy,
				sz: size,
				limitPx: limitPx,
				orderType: ["limit": ["tif": "Gtc"]]
			)
			print("Order placed:", orderRes)
			
			// Parse and cancel immediately
			if let responseString = orderRes as? String,
			   let responseData = responseString.data(using: .utf8),
			   let orderData = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
			   let response = orderData["response"] as? [String: Any],
			   let data = response["data"] as? [String: Any],
			   let statuses = data["statuses"] as? [[String: Any]],
			   let firstStatus = statuses.first,
			   let resting = firstStatus["resting"] as? [String: Any],
			   let oid = resting["oid"] as? Int64 {
				
				print("✅ Order placed successfully! OID:", oid)
				
				// Debug: Try to recover address from actual order signature
				if let responseString = orderRes as? String,
				   let responseData = responseString.data(using: .utf8),
				   let orderData = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
					print("Order response data:", orderData)
				}
				
				print("Waiting 1 second before canceling...")
				try await Task.sleep(nanoseconds: 1_000_000_000)
				
				print("Canceling order with oid:", oid)
				let cancelRes = try await exch.cancel(coin: coin, oid: oid)
				print("Cancel result:", cancelRes)
			} else {
				print("Could not parse order response")
			}
			
		} catch {
			print("Error:", error)
			if let httpError = error as? HTTPError {
				print("HTTP Error details:", httpError.localizedDescription)
			}
			exit(1)
		}
	}
}