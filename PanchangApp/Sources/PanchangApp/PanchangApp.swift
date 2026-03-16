import SwiftUI
import panchang_engine

@main
struct PanchangAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // Modern macOS look
    }
}
