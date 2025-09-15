import Foundation
import HyperliquidSwiftSDK

@main
struct BasicUpdateIsolatedMarginExample {
    static func main() async {
        struct Config: Decodable { let secret_key: String }

        func loadSecret() -> String {
            let url = URL(fileURLWithPath: "Examples/config.json")
            if let data = try? Data(contentsOf: url), let cfg = try? JSONDecoder().decode(Config.self, from: data) {
                return cfg.secret_key
            }
            return ""
        }

        let sk = loadSecret()
        guard !sk.isEmpty else { print("missing secret_key in Examples/config.json"); exit(1) }
        let base = InfoClient.defaultURL(for: .testnet)
        do {
            let client = try ExchangeClient(baseURL: base, privateKeyHex: sk)
            let response = try await client.updateIsolatedMargin(coin: "BTC", amount: 10)
            print("Update Isolated Margin Response:", response)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

