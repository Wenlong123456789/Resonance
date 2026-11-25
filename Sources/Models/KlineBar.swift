import Foundation

struct KlineBar: Identifiable, Codable, Hashable {
    let time: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let amount: Double
    
    var id: Date { time }
    
    var isBullish: Bool { close >= open }
    
    var range: Double { high - low }
    
    var bodyTop: Double { max(open, close) }
    var bodyBottom: Double { min(open, close) }
    
    /// 收盘位置 0~1
    var closePosition: Double {
        guard range > 0 else { return 0.5 }
        return (close - low) / range
    }
    
    var upperWick: Double { high - bodyTop }
    var lowerWick: Double { bodyBottom - low }
}

extension Array where Element == KlineBar {
    /// 最近 N 根最高价
    func highestHigh(_ n: Int) -> Double? {
        guard !isEmpty else { return nil }
        let slice = suffix(min(n, count))
        return slice.map(\.high).max()
    }
    
    func lowestLow(_ n: Int) -> Double? {
        guard !isEmpty else { return nil }
        let slice = suffix(min(n, count))
        return slice.map(\.low).min()
    }
}
