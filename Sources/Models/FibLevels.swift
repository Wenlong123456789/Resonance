import Foundation

/// 斐波那契回撤 / 扩展结果
struct FibLevels {
    let swingHigh: Double
    let swingLow: Double
    let highBarIndex: Int
    let lowBarIndex: Int
    let isBullishSwing: Bool      // true = 先低后高（上升波段）
    
    var range: Double { abs(swingHigh - swingLow) }
    
    // 回撤位（从终点往回）
    func retracement(_ ratio: Double) -> Double {
        if isBullishSwing {
            return swingHigh - range * ratio
        } else {
            return swingLow + range * ratio
        }
    }
    
    var r0: Double { retracement(0.0) }
    var r236: Double { retracement(0.236) }
    var r382: Double { retracement(0.382) }
    var r500: Double { retracement(0.5) }
    var r618: Double { retracement(0.618) }
    var r786: Double { retracement(0.786) }
    var r100: Double { retracement(1.0) }
    
    // 扩展位
    var ext1272Up: Double { swingHigh + range * 0.272 }
    var ext1618Up: Double { swingHigh + range * 0.618 }
    var ext2000Up: Double { swingHigh + range * 1.0 }
    
    var ext1272Down: Double { swingLow - range * 0.272 }
    var ext1618Down: Double { swingLow - range * 0.618 }
    var ext2000Down: Double { swingLow - range * 1.0 }
    
    var goldenTop: Double { max(r500, r618) }
    var goldenBottom: Double { min(r500, r618) }
    
    /// 方向性 1.618 扩展
    var directionalExt1618: Double {
        isBullishSwing ? ext1618Up : ext1618Down
    }
}

/// 波段识别（对应 Pine 的 pivot 逻辑）
struct SwingDetector {
    let pivotLen: Int
    
    init(pivotLen: Int = 20) {
        self.pivotLen = pivotLen
    }
    
    /// 返回最近有效波段的 FibLevels，如果数据不足返回 nil
    func detect(bars: [KlineBar]) -> FibLevels? {
        guard bars.count > pivotLen * 2 + 5 else { return nil }
        
        var lastHigh: Double? = nil
        var lastHighIdx: Int? = nil
        var lastLow: Double? = nil
        var lastLowIdx: Int? = nil
        var lastType: Int = 0   // 1 high, -1 low
        
        let start = pivotLen
        let end = bars.count - pivotLen - 1
        
        for i in start...end {
            let windowHigh = (i - pivotLen)...(i + pivotLen)
            let isPivotHigh = windowHigh.allSatisfy { bars[$0].high <= bars[i].high }
            let isPivotLow  = windowHigh.allSatisfy { bars[$0].low  >= bars[i].low  }
            
            if isPivotHigh {
                if lastType == 1 {
                    if lastHigh == nil || bars[i].high > lastHigh! {
                        lastHigh = bars[i].high
                        lastHighIdx = i
                    }
                } else {
                    lastHigh = bars[i].high
                    lastHighIdx = i
                    lastType = 1
                }
            }
            
            if isPivotLow {
                if lastType == -1 {
                    if lastLow == nil || bars[i].low < lastLow! {
                        lastLow = bars[i].low
                        lastLowIdx = i
                    }
                } else {
                    lastLow = bars[i].low
                    lastLowIdx = i
                    lastType = -1
                }
            }
        }
        
        guard let h = lastHigh, let hi = lastHighIdx,
              let l = lastLow, let li = lastLowIdx else { return nil }
        
        let bullish = li < hi
        return FibLevels(
            swingHigh: h,
            swingLow: l,
            highBarIndex: hi,
            lowBarIndex: li,
            isBullishSwing: bullish
        )
    }
}
