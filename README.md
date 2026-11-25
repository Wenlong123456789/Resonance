# Resonance — 斐波那契多维共振看盘终端 (iOS)

原生 SwiftUI A股/ETF 看盘 App，内置高级斐波那契体系。

## 功能（当前版本 0.1）

- 股票 / ETF 搜索（东方财富公开接口）
- 自选股（本地持久化，支持排序/删除）
- 多周期 K 线：**分时 / 5分钟 / 15分钟 / 日K / 周K / 月K**
- 原生蜡烛图（Swift Charts）
- 自动波段识别（Pivot）
- 斐波那契回撤：0 / 0.236 / 0.382 / **0.5** / **0.618** / 0.786 / 1.0
- 0.5～0.618 黄金区高亮
- 斐波那契扩展：1.272 / **1.618** / 2.0（可开关）
- 实时报价显示
- 深色交易终端主题

## 后续计划（对齐 Pine V4）

- 威廉分形 + Fib 共振标记
- 量价体系（放量突破/跌破、滞涨、止跌、黄金区量价确认）
- OBV / CMF / 量比
- RSI / MACD / KDJ + 背离
- 多维共振评分面板
- 扇形、时间周期、变盘弧线、锚定 VWAP

## 快速开始（Xcode）

### 方法一：XcodeGen（推荐）

```bash
brew install xcodegen
cd Resonance
xcodegen generate
open Resonance.xcodeproj
```

### 方法二：手动

1. 新建 iOS App 项目（SwiftUI，最低 iOS 17）
2. 删除默认 ContentView / App 文件
3. 把 `Sources` 下所有文件拖进项目
4. 把 `Resources/Info.plist` 设置为项目的 Info.plist
5. 运行

## 数据说明

使用东方财富公开接口（push2 / push2his / searchapi），无需 Key。  
请注意公开接口可能存在限流，真实设备使用通常正常。

## 目录结构

```
Sources/
├── Models/       Stock, KlineBar, Period, FibLevels
├── Services/     EastmoneyAPI, WatchlistStore
├── Views/        Search, Watchlist, ChartContainer
└── ResonanceApp.swift
Resources/
└── Info.plist
project.yml       # XcodeGen 配置
```

## 许可证

MIT（与原始研究项目一致）
