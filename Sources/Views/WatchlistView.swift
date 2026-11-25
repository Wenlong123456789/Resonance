import SwiftUI

struct WatchlistView: View {
    @ObservedObject private var store = WatchlistStore.shared
    @State private var showSearch = false
    @State private var quotes: [String: Quote] = [:]
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.stocks) { stock in
                    NavigationLink {
                        ChartContainerView(stock: stock)
                    } label: {
                        WatchlistRow(stock: stock, quote: quotes[stock.id])
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { store.remove(store.stocks[$0]) }
                }
                .onMove(perform: store.move)
            }
            .navigationTitle("自选")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
            .refreshable {
                await refreshQuotes()
            }
            .task {
                await refreshQuotes()
            }
        }
    }
    
    private func refreshQuotes() async {
        isRefreshing = true
        defer { isRefreshing = false }
        var newQuotes: [String: Quote] = [:]
        await withTaskGroup(of: (String, Quote?).self) { group in
            for stock in store.stocks {
                group.addTask {
                    do {
                        let q = try await EastmoneyAPI.shared.quote(stock: stock)
                        return (stock.id, q)
                    } catch {
                        return (stock.id, nil)
                    }
                }
            }
            for await (id, q) in group {
                if let q { newQuotes[id] = q }
            }
        }
        quotes = newQuotes
    }
}

struct WatchlistRow: View {
    let stock: Stock
    let quote: Quote?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.headline)
                Text(stock.displayCode)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let quote {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f", quote.price))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    Text(String(format: "%+.2f%%", quote.changePercent))
                        .font(.caption)
                        .foregroundStyle(quote.isUp ? Color.green : Color.red)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.vertical, 2)
    }
}
