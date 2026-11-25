import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case network(Error)
    case invalidResponse
    case emptyData
    case parseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效 URL"
        case .network(let e): return e.localizedDescription
        case .invalidResponse: return "服务器响应异常"
        case .emptyData: return "无数据返回"
        case .parseFailed(let m): return "解析失败: \(m)"
        }
    }
}

actor EastmoneyAPI {
    static let shared = EastmoneyAPI()
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            "Referer": "https://quote.eastmoney.com/",
            "Accept": "*/*"
        ]
        session = URLSession(configuration: config)
    }
    
    // MARK: - 搜索
    func search(keyword: String) async throws -> [Stock] {
        let q = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        
        // 东方财富搜索
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        let urlStr = "https://searchapi.eastmoney.com/api/suggest/get?input=\(encoded)&type=14&token=D43BF458C8F660BB36B4454AD1D93AC3&count=12"
        
        guard let url = URL(string: urlStr) else { throw APIError.invalidURL }
        
        let (data, _) = try await session.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let quoto = json["QuotationCodeTable"] as? [String: Any],
              let list = quoto["Data"] as? [[String: Any]] else {
            // 降级：尝试简单构造
            return fallbackSearch(keyword: q)
        }
        
        var results: [Stock] = []
        for item in list {
            guard let code = item["Code"] as? String,
                  let name = item["Name"] as? String,
                  let marketStr = (item["MktNum"] as? String) ?? (item["MarketType"] as? String) else { continue }
            
            let market: Stock.Market = (marketStr == "1" || marketStr.uppercased().contains("SH")) ? .SH : .SZ
            // 过滤非A股
            if code.count == 6, code.allSatisfy(\.isNumber) {
                results.append(Stock(code: code, name: name, market: market))
            }
        }
        return results.isEmpty ? fallbackSearch(keyword: q) : results
    }
    
    private func fallbackSearch(keyword: String) -> [Stock] {
        // 简单本地兜底（常见股票）
        let common: [(String, String, Stock.Market)] = [
            ("600519", "贵州茅台", .SH),
            ("000001", "平安银行", .SZ),
            ("000858", "五粮液", .SZ),
            ("601318", "中国平安", .SH),
            ("600036", "招商银行", .SH),
            ("300750", "宁德时代", .SZ),
            ("002594", "比亚迪", .SZ),
            ("510300", "沪深300ETF", .SH),
            ("510500", "中证500ETF", .SH),
            ("159915", "创业板ETF", .SZ)
        ]
        return common
            .filter { $0.0.contains(keyword) || $0.1.contains(keyword) }
            .map { Stock(code: $0.0, name: $0.1, market: $0.2) }
    }
    
    // MARK: - K线
    func klines(stock: Stock, period: ChartPeriod, limit: Int = 300) async throws -> [KlineBar] {
        if period == .intraday {
            return try await trends(stock: stock)
        }
        
        let klt = period.eastmoneyKlt
        let urlStr = "https://push2his.eastmoney.com/api/qt/stock/kline/get?secid=\(stock.secid)&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61&klt=\(klt)&fqt=1&end=20500101&lmt=\(limit)"
        
        guard let url = URL(string: urlStr) else { throw APIError.invalidURL }
        
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let klineArr = dataObj["klines"] as? [String] else {
            throw APIError.emptyData
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if period.isIntraday {
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
        }
        
        var bars: [KlineBar] = []
        for line in klineArr {
            // 格式: 日期,开,收,高,低,成交量,成交额,振幅,涨跌幅,涨跌额,换手率
            let parts = line.split(separator: ",").map(String.init)
            guard parts.count >= 7,
                  let date = formatter.date(from: parts[0]),
                  let open = Double(parts[1]),
                  let close = Double(parts[2]),
                  let high = Double(parts[3]),
                  let low = Double(parts[4]),
                  let volume = Double(parts[5]),
                  let amount = Double(parts[6]) else { continue }
            
            bars.append(KlineBar(
                time: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume,
                amount: amount
            ))
        }
        return bars
    }
    
    /// 分时（当日趋势）
    private func trends(stock: Stock) async throws -> [KlineBar] {
        let urlStr = "https://push2his.eastmoney.com/api/qt/stock/trends2/get?secid=\(stock.secid)&fields1=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13&fields2=f51,f52,f53,f54,f55,f56,f57,f58&iscr=0&ndays=1"
        guard let url = URL(string: urlStr) else { throw APIError.invalidURL }
        
        let (data, _) = try await session.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let trends = dataObj["trends"] as? [String] else {
            throw APIError.emptyData
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        var bars: [KlineBar] = []
        for line in trends {
            // 时间,价格,均价,成交量,成交额...
            let parts = line.split(separator: ",").map(String.init)
            guard parts.count >= 4,
                  let date = formatter.date(from: parts[0]),
                  let price = Double(parts[1]),
                  let volume = Double(parts[3]) else { continue }
            
            // 分时用价格当 OHLC
            bars.append(KlineBar(
                time: date,
                open: price,
                high: price,
                low: price,
                close: price,
                volume: volume,
                amount: parts.count > 4 ? (Double(parts[4]) ?? 0) : 0
            ))
        }
        return bars
    }
    
    // MARK: - 实时行情（单只）
    func quote(stock: Stock) async throws -> Quote {
        let urlStr = "https://push2.eastmoney.com/api/qt/stock/get?secid=\(stock.secid)&fields=f43,f44,f45,f46,f47,f48,f57,f58,f60,f169,f170,f168,f167,f162,f46,f44"
        guard let url = URL(string: urlStr) else { throw APIError.invalidURL }
        
        let (data, _) = try await session.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let d = json["data"] as? [String: Any] else {
            throw APIError.emptyData
        }
        
        // 东财价格多数是放大100倍的整数
        func p(_ key: String) -> Double {
            if let v = d[key] as? Double { return v / 100.0 }
            if let v = d[key] as? Int { return Double(v) / 100.0 }
            return 0
        }
        
        let price = p("f43")
        let high = p("f44")
        let low = p("f45")
        let open = p("f46")
        let preClose = p("f60")
        let change = price - preClose
        let changePct = preClose > 0 ? change / preClose * 100 : 0
        
        let volume = (d["f47"] as? Double) ?? (d["f47"] as? Int).map(Double.init) ?? 0
        let amount = (d["f48"] as? Double) ?? (d["f48"] as? Int).map(Double.init) ?? 0
        
        return Quote(
            stock: stock,
            price: price,
            open: open,
            high: high,
            low: low,
            preClose: preClose,
            volume: volume,
            amount: amount,
            change: change,
            changePercent: changePct,
            time: Date()
        )
    }
}
