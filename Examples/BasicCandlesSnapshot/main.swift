import Foundation
import HyperliquidSwiftSDK

@main
struct BasicCandlesSnapshotExample {
    static func main() async {
        let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            let endTime = Int64(Date().timeIntervalSince1970 * 1000)
            let startTime = endTime - 86400000 // 24 hours ago
            let candles = try await client.candlesSnapshot(coin: "BTC", interval: "1h", startTime: startTime, endTime: endTime)
            print("Candles Snapshot:", candles)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

