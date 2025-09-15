import Foundation
import HyperliquidSwiftSDK

@main
struct BasicUpdateLeverageExample {
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
            let response = try await client.updateLeverage(coin: "BTC", isCross: true, leverage: 20)
            print("Update Leverage Response:", response)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

