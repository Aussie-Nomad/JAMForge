// JAMForge/App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSidebarItem: SidebarItem = .profiles
    
    var body: some View {
        NavigationSplitView {
            // Sidebar Navigation
            SidebarView(selectedItem: $selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // Content Area (Profile List, Templates, etc.)
            ContentAreaView(selectedItem: selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
        } detail: {
            // Detail View (Profile Editor, Settings, etc.)
            DetailAreaView(selectedItem: selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 500, ideal: 600)
        }
        .navigationTitle("JAMForge")
        .toolbar {
            MainToolbar(selectedItem: selectedSidebarItem)
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showJAMFConnection) {
            JAMFConnectionView(profile: appState.selectedProfile)
                .environmentObject(appState)
        }
        .alert("Error", isPresented: $appState.showAlert) {
            Button("OK") {
                appState.showAlert = false
                appState.alertMessage = nil
            }
        } message: {
            if let message = appState.alertMessage {
                Text(message)
            }
        }
    }
}

// MARK: - Sidebar Items
enum SidebarItem: String, CaseIterable, Identifiable {
    case profiles = "Profiles"
    case templates = "Templates"
    case jamf = "JAMF Pro"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .profiles: return "doc.text"
        case .templates: return "doc.on.doc"
        case .jamf: return "server.rack"
        case .settings: return "gear"
        }
    }
    
    var description: String {
        switch self {
        case .profiles: return "Configuration Profiles"
        case .templates: return "Profile Templates"
        case .jamf: return "JAMF Pro Integration"
        case .settings: return "Application Settings"
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            NavigationLink(value: item) {
                Label(item.rawValue, systemImage: item.icon)
            }
        }
        .navigationTitle("JAMForge")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

// MARK: - Content Area View
struct ContentAreaView: View {
    let selectedItem: SidebarItem
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            switch selectedItem {
            case .profiles:
                ProfileListView()
            case .templates:
                TemplateListView()
            case .jamf:
                JAMFStatusView()
            case .settings:
                Text("Settings")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(selectedItem.rawValue)
    }
}

// MARK: - Detail Area View
struct DetailAreaView: View {
    let selectedItem: SidebarItem
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            switch selectedItem {
            case .profiles:
                if let selectedProfile = appState.selectedProfile {
                    ProfileDetailView(profile: selectedProfile)
                } else {
                    ProfileEmptyStateView()
                }
            case .templates:
                TemplateDetailView()
            case .jamf:
                JAMFDetailView()
            case .settings:
                SettingsDetailView()
            }
        }
    }
}

// MARK: - Main Toolbar
struct MainToolbar: View {
    let selectedItem: SidebarItem
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            switch selectedItem {
            case .profiles:
                ProfileToolbar()
            case .templates:
                TemplateToolbar()
            case .jamf:
                JAMFToolbar()
            case .settings:
                SettingsToolbar()
            }
        }
    }
}

// MARK: - Profile Toolbar
struct ProfileToolbar: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            Button("New Profile") {
                createNewProfile()
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("New from Template") {
                appState.showTemplateLibrary = true
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            if appState.selectedProfile != nil {
                Divider()
                
                Button("Export") {
                    exportProfile()
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button("Deploy to JAMF") {
                    appState.showJAMFConnection = true
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(!appState.isJAMFConnected)
            }
        }
    }
    
    private func createNewProfile() {
        let newProfile = ConfigurationProfile(
            name: "New Profile",
            identifier: "com.company.newprofile"
        )
        appState.profiles.append(newProfile)
        appState.selectedProfile = newProfile
    }
    
    private func exportProfile() {
        // TODO: Implement profile export
        appState.showError("Export functionality not yet implemented")
    }
}

// MARK: - Template Toolbar
struct TemplateToolbar: View {
    var body: some View {
        HStack {
            Button("Browse Templates") {
                // TODO: Implement template browsing
            }
            
            Button("Create Template") {
                // TODO: Implement template creation
            }
        }
    }
}

// MARK: - JAMF Toolbar
struct JAMFToolbar: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            Button("Connect") {
                appState.showJAMFConnection = true
            }
            .disabled(appState.isJAMFConnected)
            
            if appState.isJAMFConnected {
                Button("Disconnect") {
                    // TODO: Implement JAMF disconnect
                }
            }
        }
    }
}

// MARK: - Settings Toolbar
struct SettingsToolbar: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            Button("Preferences") {
                appState.showSettings = true
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 1200, height: 800)
}