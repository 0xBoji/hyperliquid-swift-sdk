import Foundation
import HyperliquidSwiftSDK

@main
struct BasicUserFillsExample {
    static func main() async {
        let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            // Replace with a valid user address
            let user = "0x3ed4033676d0bdb3938728ca4ac673d00e74bd06"
            let fills = try await client.userFills(user: user)
            print("User Fills:", fills)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

