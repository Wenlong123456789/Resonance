import Foundation

struct Stock: Identifiable, Codable, Hashable {
    let code: String          // 600519 / 000001
    let name: String
    let market: Market        // SH / SZ
    
    var id: String { "\(market.rawValue)\(code)" }
    
    /// 东方财富 secid: 1.600519 (沪) / 0.000001 (深)
    var secid: String {
        "\(market.eastmoneyPrefix).\(code)"
    }
    
    var displayCode: String {
        "\(code).\(market.rawValue)"
    }
    
    enum Market: String, Codable, CaseIterable {
        case SH, SZ
        
        var eastmoneyPrefix: Int {
            switch self {
            case .SH: return 1
            case .SZ: return 0
            }
        }
        
        var sinaPrefix: String {
            switch self {
            case .SH: return "sh"
            case .SZ: return "sz"
            }
        }
    }
    
    static func from(code: String, name: String) -> Stock? {
        let clean = code.uppercased()
            .replacingOccurrences(of: "SH", with: "")
            .replacingOccurrences(of: "SZ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        guard clean.count == 6, clean.allSatisfy({ $0.isNumber }) else { return nil }
        
        let market: Market
        if clean.hasPrefix("6") || clean.hasPrefix("9") {
            market = .SH
        } else {
            market = .SZ
        }
        return Stock(code: clean, name: name, market: market)
    }
}

struct Quote: Codable {
    let stock: Stock
    let price: Double
    let open: Double
    let high: Double
    let low: Double
    let preClose: Double
    let volume: Double          // 手 or 股，按接口
    let amount: Double
    let change: Double
    let changePercent: Double
    let time: Date?
    
    var isUp: Bool { change >= 0 }
}
