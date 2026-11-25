import Foundation

/// 支持的K线周期
enum ChartPeriod: String, CaseIterable, Identifiable, Codable {
    case intraday = "分时"
    case m5 = "5分"
    case m15 = "15分"
    case daily = "日K"
    case weekly = "周K"
    case monthly = "月K"
    
    var id: String { rawValue }
    
    /// 东方财富 klt 参数
    var eastmoneyKlt: Int {
        switch self {
        case .intraday: return 1      // 1分钟（分时用 trends 或 1min）
        case .m5: return 5
        case .m15: return 15
        case .daily: return 101
        case .weekly: return 102
        case .monthly: return 103
        }
    }
    
    /// 显示名称
    var title: String { rawValue }
    
    /// 是否为分钟级
    var isIntraday: Bool {
        switch self {
        case .intraday, .m5, .m15: return true
        default: return false
        }
    }
}
