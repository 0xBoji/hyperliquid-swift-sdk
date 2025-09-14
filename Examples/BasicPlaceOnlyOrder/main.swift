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
struct BasicPlaceOnlyOrder {
	static func main() async {
		let sk = loadSecret()
		guard !sk.isEmpty else { print("missing secret_key in Examples/config.json"); exit(1) }
		let base = InfoClient.defaultURL(for: .testnet)
		do {
			let exch = try ExchangeClient(baseURL: base, privateKeyHex: sk)
			// Place a resting limit buy well below market, Alo (post-only)
			let coin = "ETH"
			let isBuy = true
			let size = 0.2
			let limitPx = 4400.0

			let res = try await exch.order(
				coin: coin,
				isBuy: isBuy,
				sz: size,
				limitPx: limitPx,
				orderType: ["limit": ["tif": "Alo"]]
			)
			print(res)
		} catch {
			print("Error:", error)
			exit(1)
		}
	}
}


