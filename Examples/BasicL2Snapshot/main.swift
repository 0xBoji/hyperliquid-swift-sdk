import Foundation
import HyperliquidSwiftSDK

@main
struct BasicL2SnapshotExample {
    static func main() async {
        let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            let snapshot = try await client.l2Snapshot(coin: "BTC")
            print("L2 Snapshot:", snapshot)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

