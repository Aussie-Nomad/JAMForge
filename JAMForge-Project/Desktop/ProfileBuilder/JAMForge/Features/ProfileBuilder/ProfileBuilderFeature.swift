import SwiftUI
import JAMForgeKit

public struct ProfileBuilderFeature: View {
    @StateObject private var viewModel = ProfileBuilderViewModel()
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar with profiles list
            ProfileListView()
                .environmentObject(viewModel)
        } detail: {
            // Profile editor
            if let selectedProfile = viewModel.selectedProfile {
                ProfileEditorView(profile: selectedProfile)
            } else {
                Text("Select or create a profile")
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ProfileBuilderToolbar(viewModel: viewModel)
        }
    }
}

class ProfileBuilderViewModel: ObservableObject {
    @Published var selectedProfile: ConfigurationProfile?
    @Published var profiles: [ConfigurationProfile] = []
    @Published var showingNewProfileSheet = false
    @Published var showingJAMFConnection = false
    
    private let profileService: ProfileService
    
    init(profileService: ProfileService = ProfileService()) {
        self.profileService = profileService
        loadProfiles()
    }
    
    private func loadProfiles() {
        // Load saved profiles
        do {
            profiles = try profileService.loadAllProfiles()
        } catch {
            // Handle error
            print("Error loading profiles: \(error)")
        }
    }
}
