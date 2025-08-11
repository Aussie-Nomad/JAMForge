import SwiftUI

@main
struct JAMForgeProfileCreatorApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark) // Enforce dark mode
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
struct JAMForgeProfileCreatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
