import Foundation
import HyperliquidSwiftSDK

@main
struct BasicFundingHistoryExample {
    static func main() async {
        let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            let startTime = Int64(Date().timeIntervalSince1970 * 1000) - 86400000 // 24 hours ago
            let history = try await client.fundingHistory(coin: "BTC", startTime: startTime)
            print("Funding History:", history)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

