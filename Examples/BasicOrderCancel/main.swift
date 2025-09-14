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
			
			// Place a limit order with unique client order ID
			let coin = "ETH"
			let isBuy = true
			let size = 0.01
			let limitPx = 4400.0
			let cloid = "swift-cancel-\(Int(Date().timeIntervalSince1970))"
			
			print("Placing order with cloid: \(cloid)")
			let orderRes = try await exch.order(
				coin: coin,
				isBuy: isBuy,
				sz: size,
				limitPx: limitPx,
				orderType: ["limit": ["tif": "Gtc"]],
				cloid: cloid
			)
			print("Order placed:", orderRes)
			
			// Wait a moment then cancel
			print("Waiting 2 seconds before canceling...")
			try await Task.sleep(nanoseconds: 2_000_000_000)
			
			// Cancel by client order ID
			print("Canceling order by cloid: \(cloid)")
			let cancelRes = try await exch.cancelByCloid(cloid: cloid)
			print("Order canceled:", cancelRes)
			
		} catch {
			print("Error:", error)
			exit(1)
		}
	}
}