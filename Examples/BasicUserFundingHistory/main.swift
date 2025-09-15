import Foundation
import HyperliquidSwiftSDK

@main
struct BasicUserFundingHistoryExample {
    static func main() async {
        let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            // Replace with a valid user address
            let user = "0x0000000000000000000000000000000000000000"
            let endTime = Int64(Date().timeIntervalSince1970 * 1000)
            let startTime = endTime - 86400000 // 24 hours ago
            let history = try await client.userFundingHistory(user: user, startTime: startTime)
            print("User Funding History:", history)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

