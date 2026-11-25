import SwiftUI

struct SearchView: View {
    @State private var keyword = ""
    @State private var results: [Stock] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @ObservedObject private var watchlist = WatchlistStore.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                
                ForEach(results) { stock in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stock.name)
                                .font(.headline)
                            Text(stock.displayCode)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            if watchlist.contains(stock) {
                                watchlist.remove(stock)
                            } else {
                                watchlist.add(stock)
                            }
                        } label: {
                            Image(systemName: watchlist.contains(stock) ? "star.fill" : "star")
                                .foregroundStyle(watchlist.contains(stock) ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        watchlist.add(stock)
                        dismiss()
                    }
                }
            }
            .navigationTitle("搜索股票 / ETF")
            .searchable(text: $keyword, prompt: "代码或名称")
            .onChange(of: keyword) { _, newValue in
                Task { await doSearch(newValue) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private func doSearch(_ text: String) async {
        let q = text.trimmingCharacters(in: .whitespaces)
        guard q.count >= 1 else {
            results = []
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            results = try await EastmoneyAPI.shared.search(keyword: q)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
        isLoading = false
    }
}
