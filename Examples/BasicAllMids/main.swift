import Foundation
import HyperliquidSwiftSDK

@main
struct BasicAllMidsExample {
    static func main() async {
        let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            let mids = try await client.allMids()
            print("ETH mid:", mids["ETH"] ?? "")
            print("BTC mid:", mids["BTC"] ?? "")
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}



