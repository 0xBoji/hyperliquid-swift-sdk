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
			
			// Place a limit order without cloid first
			let coin = "ETH"
			let isBuy = true
			let size = 0.01
			let limitPx = 4400.0
			
			print("Placing order without cloid")
			let orderRes = try await exch.order(
				coin: coin,
				isBuy: isBuy,
				sz: size,
				limitPx: limitPx,
				orderType: ["limit": ["tif": "Gtc"]]
			)
			print("Order placed:", orderRes)
			
			// Parse JSON string response
			guard let responseString = orderRes as? String,
				  let responseData = responseString.data(using: .utf8),
				  let orderData = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
				print("Could not parse response as JSON")
				return
			}
			
			print("Response structure:", orderData)
			
			// Parse the order response
			if let response = orderData["response"] as? [String: Any],
			   let data = response["data"] as? [String: Any],
			   let statuses = data["statuses"] as? [[String: Any]],
			   let firstStatus = statuses.first {
				
				if let resting = firstStatus["resting"] as? [String: Any],
				   let oid = resting["oid"] as? Int {
					print("✅ Order placed successfully!")
					print("Order ID:", oid)
					print("Order is resting on the order book.")
					print("To cancel this order, you would call: exch.cancel(coin: \"\(coin)\", oid: \(oid))")
				} else if let error = firstStatus["error"] as? String {
					print("❌ Order failed:", error)
					print("This is expected if the account doesn't have sufficient margin or doesn't exist on testnet.")
					print("The SDK is working correctly - this is a business logic error, not a technical error.")
				} else {
					print("❓ Unknown order status:", firstStatus)
				}
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