import Foundation
import HyperliquidSwiftSDK

@main
struct BasicOrderStatusExample {
    static func main() async {
        let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            // Replace with a valid user address and order ID
            let user = "0x0000000000000000000000000000000000000000"
            let oid: Int64 = 0
            let status = try await client.orderStatus(user: user, oid: oid)
            print("Order Status:", status)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

