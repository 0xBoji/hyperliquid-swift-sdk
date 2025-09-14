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
			
			// Parse the order ID from response
			if let response = orderData["response"] as? [String: Any],
			   let data = response["data"] as? [String: Any],
			   let statuses = data["statuses"] as? [[String: Any]],
			   let firstStatus = statuses.first,
			   let resting = firstStatus["resting"] as? [String: Any],
			   let oid = resting["oid"] as? Int {
				
				print("Order ID:", oid)
				
				// Wait a moment then cancel
				print("Waiting 2 seconds before canceling...")
				try await Task.sleep(nanoseconds: 2_000_000_000)
				
				// Cancel by order ID
				print("Canceling order by oid:", oid)
				let cancelRes = try await exch.cancel(coin: coin, oid: oid)
				print("Order canceled:", cancelRes)
			} else {
				print("Could not parse order ID from response")
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