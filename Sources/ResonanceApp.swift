import SwiftUI

@main
struct ResonanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            WatchlistView()
                .tabItem {
                    Label("自选", systemImage: "star.fill")
                }
            
            // 后续可加行情、板块等
            Text("更多功能开发中")
                .foregroundStyle(.secondary)
                .tabItem {
                    Label("发现", systemImage: "chart.bar")
                }
        }
        .tint(.orange)
    }
}
