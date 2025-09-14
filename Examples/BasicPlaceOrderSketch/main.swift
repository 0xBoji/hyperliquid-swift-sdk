import Foundation

struct OrderWire: Codable {
    let a: Int
    let b: Bool
    let p: String
    let s: String
    let r: Bool
    let t: [String: [String: String]]
    let c: String?
}

struct OrderAction: Codable {
    let type: String = "order"
    let orders: [OrderWire]
    let grouping: String = "na"
}

@main
struct BasicPlaceOrderSketch {
    static func main() throws {
        let example = OrderAction(orders: [
            .init(a: 0, b: true, p: "30000", s: "0.1", r: false, t: ["limit": ["tif": "Gtc"]], c: nil)
        ])
        let data = try JSONEncoder().encode(example)
        print(String(data: data, encoding: .utf8)!)
    }
}


