import SwiftUI
import Charts

struct ChartContainerView: View {
    let stock: Stock
    
    @State private var period: ChartPeriod = .daily
    @State private var bars: [KlineBar] = []
    @State private var fib: FibLevels? = nil
    @State private var isLoading = false
    @State private var error: String?
    @State private var showFib = true
    @State private var showExt = true
    @State private var quote: Quote?
    
    private let detector = SwingDetector(pivotLen: 20)
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部报价
            if let q = quote {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(String(format: "%.2f", q.price))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(q.isUp ? Color.green : Color.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%+.2f  %+.2f%%", q.change, q.changePercent))
                            .font(.caption)
                            .foregroundStyle(q.isUp ? Color.green : Color.red)
                        Text("高 \(String(format: "%.2f", q.high))  低 \(String(format: "%.2f", q.low))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            
            // 周期切换
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ChartPeriod.allCases) { p in
                        Button {
                            period = p
                            Task { await load() }
                        } label: {
                            Text(p.title)
                                .font(.subheadline.weight(period == p ? .semibold : .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(period == p ? Color.orange.opacity(0.28) : Color.white.opacity(0.06))
                                .clipShape(Capsule())
                                .foregroundStyle(period == p ? .orange : .secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            
            // 工具栏
            HStack(spacing: 16) {
                Toggle(isOn: $showFib) {
                    Text("Fib回撤").font(.caption)
                }
                .toggleStyle(.button)
                
                Toggle(isOn: $showExt) {
                    Text("扩展").font(.caption)
                }
                .toggleStyle(.button)
                
                Spacer()
                
                if let fib {
                    Text(fib.isBullishSwing ? "↑上升波段" : "↓下降波段")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(fib.isBullishSwing ? .green : .red)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
            
            if isLoading {
                Spacer()
                ProgressView("加载中…")
                Spacer()
            } else if let error {
                Spacer()
                VStack(spacing: 12) {
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("重试") { Task { await load() } }
                        .buttonStyle(.bordered)
                }
                Spacer()
            } else if bars.isEmpty {
                Spacer()
                Text("暂无数据")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                CandleChartView(
                    bars: bars,
                    fib: showFib ? fib : nil,
                    showExt: showExt,
                    period: period
                )
                
                if let fib {
                    HStack {
                        Label("0.618 \(String(format: "%.2f", fib.r618))", systemImage: "arrow.left.and.right")
                        Spacer()
                        if showExt {
                            Text("1.618 \(String(format: "%.2f", fib.directionalExt1618))")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.orange.opacity(0.9))
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("\(stock.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(stock.name).font(.headline)
                    Text(stock.displayCode).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .task(id: period) {
            await load()
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.06).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
    
    private func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let klineTask = EastmoneyAPI.shared.klines(stock: stock, period: period, limit: period.isIntraday ? 240 : 300)
            async let quoteTask = EastmoneyAPI.shared.quote(stock: stock)
            
            let (data, q) = try await (klineTask, quoteTask)
            bars = data
            quote = q
            fib = detector.detect(bars: data)
        } catch {
            self.error = error.localizedDescription
            bars = []
            fib = nil
        }
    }
}

struct CandleChartView: View {
    let bars: [KlineBar]
    let fib: FibLevels?
    let showExt: Bool
    let period: ChartPeriod
    
    var body: some View {
        Chart {
            ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                RuleMark(
                    x: .value("T", index),
                    yStart: .value("L", bar.low),
                    yEnd: .value("H", bar.high)
                )
                .foregroundStyle(bar.isBullish ? Color.green.opacity(0.75) : Color.red.opacity(0.75))
                .lineStyle(StrokeStyle(lineWidth: 1.2))
                
                RectangleMark(
                    x: .value("T", index),
                    yStart: .value("O", bar.bodyBottom),
                    yEnd: .value("C", bar.bodyTop),
                    width: period.isIntraday ? 2.5 : 5
                )
                .foregroundStyle(bar.isBullish ? Color.green : Color.red)
            }
            
            if let fib {
                fibLine(fib.r0, "0", .gray.opacity(0.5), dashed: true)
                fibLine(fib.r236, "0.236", .gray.opacity(0.6), dashed: true)
                fibLine(fib.r382, "0.382", .blue.opacity(0.85), dashed: false)
                fibLine(fib.r500, "0.5", .yellow, dashed: false)
                fibLine(fib.r618, "0.618", .orange, dashed: false, width: 2.2)
                fibLine(fib.r786, "0.786", .purple.opacity(0.8), dashed: true)
                fibLine(fib.r100, "1.0", .gray.opacity(0.5), dashed: true)
                
                RectangleMark(
                    xStart: .value("x", 0),
                    xEnd: .value("x", max(bars.count - 1, 1)),
                    yStart: .value("y", fib.goldenBottom),
                    yEnd: .value("y", fib.goldenTop)
                )
                .foregroundStyle(Color.orange.opacity(0.07))
                
                if showExt {
                    if fib.isBullishSwing {
                        fibLine(fib.ext1272Up, "1.272", .cyan.opacity(0.7), dashed: true)
                        fibLine(fib.ext1618Up, "1.618", .orange, dashed: false, width: 1.8)
                        fibLine(fib.ext2000Up, "2.0", .red.opacity(0.6), dashed: true)
                    } else {
                        fibLine(fib.ext1272Down, "1.272", .cyan.opacity(0.7), dashed: true)
                        fibLine(fib.ext1618Down, "1.618", .orange, dashed: false, width: 1.8)
                        fibLine(fib.ext2000Down, "2.0", .red.opacity(0.6), dashed: true)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.white.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.white.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .chartXScale(domain: -2...(bars.count + 8))
        .padding(.horizontal, 4)
        .frame(maxHeight: .infinity)
    }
    
    @ChartContentBuilder
    private func fibLine(_ price: Double, _ label: String, _ color: Color, dashed: Bool, width: CGFloat = 1) -> some ChartContent {
        RuleMark(y: .value(label, price))
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: width, dash: dashed ? [5, 4] : []))
            .annotation(position: .trailing, alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.leading, 2)
            }
    }
}
