import Foundation
import HyperliquidSwiftSDK

@main
struct BasicMetaAndAssetCtxsExample {
    static func main() async {
        let client = InfoClient(config: .init(baseURL: InfoClient.defaultURL(for: .mainnet)))
        do {
            let data = try await client.metaAndAssetCtxs()
            print("Meta and Asset Ctxs:", data)
        } catch {
            print("Error:", error)
            exit(1)
        }
    }
}

