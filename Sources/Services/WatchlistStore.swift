import Foundation
import Combine

@MainActor
final class WatchlistStore: ObservableObject {
    static let shared = WatchlistStore()
    
    @Published private(set) var stocks: [Stock] = []
    
    private let key = "resonance.watchlist"
    
    private init() {
        load()
    }
    
    func add(_ stock: Stock) {
        guard !stocks.contains(where: { $0.id == stock.id }) else { return }
        stocks.insert(stock, at: 0)
        save()
    }
    
    func remove(_ stock: Stock) {
        stocks.removeAll { $0.id == stock.id }
        save()
    }
    
    func contains(_ stock: Stock) -> Bool {
        stocks.contains { $0.id == stock.id }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        stocks.move(fromOffsets: source, toOffset: destination)
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Stock].self, from: data) else {
            // 默认自选
            stocks = [
                Stock(code: "600519", name: "贵州茅台", market: .SH),
                Stock(code: "000001", name: "平安银行", market: .SZ),
                Stock(code: "510300", name: "沪深300ETF", market: .SH)
            ]
            return
        }
        stocks = list
    }
}
