import SwiftUI

@main
struct JAMForgeApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    setupAppearance()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            JAMForgeCommands()
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
    
    private func setupAppearance() {
        // Configure app-wide appearance
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }
}

struct JAMForgeCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Profile") {
                // Create new profile
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("New from Template") {
                // Open template library
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }
        
        CommandGroup(after: .importExport) {
            Button("Export Profile...") {
                // Export current profile
            }
            .keyboardShortcut("e", modifiers: .command)
            
            Button("Deploy to JAMF...") {
                // Open JAMF deployment
            }
            .keyboardShortcut("d", modifiers: .command)
        }
    }
}
