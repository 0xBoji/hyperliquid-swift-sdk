import Foundation
import HyperliquidSwiftSDK

@main
struct BasicHistoricalOrdersExample {
    static func main() async {
                let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            // Replace with a valid user address
            let user = "0x0000000000000000000000000000000000000000"
            let orders = try await client.historicalOrders(user: user)
            print("Historical Orders:", orders)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

