// JAMForge/App/AppState.swift - Updated with proper service integration
import SwiftUI
import Combine
import Logging

class AppState: ObservableObject {
    
    // MARK: - Services
    private let profileService = ProfileService()
    private let jamfService = JAMFAPIService()
    private let logger = Logger(label: "AppState")
    
    // MARK: - Profile Management
    @Published var selectedProfile: ConfigurationProfile?
    @Published var profiles: [ConfigurationProfile] = []
    
    // MARK: - JAMF Integration
    @Published var isJAMFConnected: Bool = false
    @Published var jamfServerInfo: JAMFServerInfo?
    
    // MARK: - Template Management
    @Published var templates: [ProfileTemplate] = []
    
    // MARK: - UI State
    @Published var selectedTab: Int = 0
    @Published var isDarkMode: Bool = true
    
    // Sheet presentation
    @Published var showSettings: Bool = false
    @Published var showTemplateLibrary: Bool = false
    @Published var showJAMFConnection: Bool = false
    
    // MARK: - Analysis State
    @Published var isAnalyzing: Bool = false
    @Published var analysisResults: [AppAnalysisResult] = []
    
    // MARK: - Error Handling
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false
    
    // MARK: - Loading States
    @Published var isLoadingProfiles: Bool = false
    @Published var isSavingProfile: Bool = false
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialState()
    }
    
    private func setupBindings() {
        // Bind JAMF service state to AppState
        jamfService.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isJAMFConnected = isConnected
            }
            .store(in: &cancellables)
        
        jamfService.$serverInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] serverInfo in
                self?.jamfServerInfo = serverInfo
            }
            .store(in: &cancellables)
        
        // Auto-save when profile changes
        $selectedProfile
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] profile in
                if let profile = profile {
                    self?.saveProfile(profile, showSuccess: false)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialState() {
        Task {
            await loadProfiles()
            await loadTemplates()
            await loadUserPreferences()
        }
    }
    
    // MARK: - Profile Management
    
    /// Load all profiles from disk
    @MainActor
    func loadProfiles() async {
        isLoadingProfiles = true
        
        do {
            let loadedProfiles = try profileService.loadAllProfiles()
            profiles = loadedProfiles
            logger.info("Loaded \(loadedProfiles.count) profiles")
        } catch {
            showError("Failed to load profiles: \(error.localizedDescription)")
            logger.error("Failed to load profiles: \(error)")
        }
        
        isLoadingProfiles = false
    }
    
    /// Create a new profile
    func createNewProfile(name: String? = nil, identifier: String? = nil) {
        let profileName = name ?? "New Profile"
        let profile = profileService.createProfile(
            name: profileName,
            identifier: identifier,
            organization: "My Organization"
        )
        
        profiles.append(profile)
        selectedProfile = profile
        
        // Save immediately
        saveProfile(profile)
        
        logger.info("Created new profile: \(profileName)")
    }
    
    /// Save profile to disk
    func saveProfile(_ profile: ConfigurationProfile, showSuccess: Bool = true) {
        Task {
            await MainActor.run {
                isSavingProfile = true
            }
            
            do {
                try profileService.saveProfile(profile)
                
                await MainActor.run {
                    // Update the profile in our array
                    if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                        profiles[index] = profile
                    }
                    
                    if showSuccess {
                        // Could show a subtle success indicator
                        logger.info("Saved profile: \(profile.payloadDisplayName)")
                    }
                }
            } catch {
                await MainActor.run {
                    showError("Failed to save profile: \(error.localizedDescription)")
                }
                logger.error("Failed to save profile: \(error)")
            }
            
            await MainActor.run {
                isSavingProfile = false
            }
        }
    }
    
    /// Delete profile
    func deleteProfile(_ profile: ConfigurationProfile) {
        Task {
            do {
                try profileService.deleteProfile(profile)
                
                await MainActor.run {
                    profiles.removeAll { $0.id == profile.id }
                    if selectedProfile?.id == profile.id {
                        selectedProfile = nil
                    }
                }
                
                logger.info("Deleted profile: \(profile.payloadDisplayName)")
            } catch {
                await MainActor.run {
                    showError("Failed to delete profile: \(error.localizedDescription)")
                }
                logger.error("Failed to delete profile: \(error)")
            }
        }
    }
    
    /// Duplicate profile
    func duplicateProfile(_ profile: ConfigurationProfile) {
        let duplicatedProfile = profileService.duplicateProfile(profile)
        profiles.append(duplicatedProfile)
        selectedProfile = duplicatedProfile
        saveProfile(duplicatedProfile)
        
        logger.info("Duplicated profile: \(profile.payloadDisplayName)")
    }
    
    /// Export profile
    func exportProfile(_ profile: ConfigurationProfile, to url: URL) {
        Task {
            do {
                try profileService.exportProfile(profile, to: url)
                logger.info("Exported profile: \(profile.payloadDisplayName)")
                
                // Could show success notification
            } catch {
                await MainActor.run {
                    showError("Failed to export profile: \(error.localizedDescription)")
                }
                logger.error("Failed to export profile: \(error)")
            }
        }
    }
    
    // MARK: - JAMF Integration
    
    /// Connect to JAMF Pro
    func connectToJAMF(serverURL: String, username: String, password: String) {
        Task {
            do {
                try await jamfService.connect(to: serverURL, username: username, password: password)
                logger.info("Connected to JAMF Pro successfully")
            } catch {
                await MainActor.run {
                    showError("Failed to connect to JAMF Pro: \(error.localizedDescription)")
                }
                logger.error("JAMF connection failed: \(error)")
            }
        }
    }
    
    /// Disconnect from JAMF Pro
    func disconnectFromJAMF() {
        Task {
            await jamfService.disconnect()
            logger.info("Disconnected from JAMF Pro")
        }
    }
    
    /// Deploy profile to JAMF Pro
    func deployProfileToJAMF(_ profile: ConfigurationProfile, scope: ScopeTargets = ScopeTargets()) {
        guard isJAMFConnected else {
            showError("Not connected to JAMF Pro")
            return
        }
        
        Task {
            do {
                let response = try await jamfService.uploadProfile(profile)
                
                // Update scope if not deploying to all computers
                if !scope.allComputers {
                    try await jamfService.updateProfileScope(profileId: response.id, scope: scope)
                }
                
                await MainActor.run {
                    // Could show success notification with profile ID
                    logger.info("Successfully deployed profile \(profile.payloadDisplayName) to JAMF Pro (ID: \(response.id))")
                }
                
            } catch {
                await MainActor.run {
                    showError("Failed to deploy profile: \(error.localizedDescription)")
                }
                logger.error("JAMF deployment failed: \(error)")
            }
        }
    }
    
    // MARK: - Template Management
    
    /// Load available templates
    @MainActor
    private func loadTemplates() async {
        do {
            templates = try profileService.loadTemplates()
            logger.info("Loaded \(templates.count) templates")
        } catch {
            showError("Failed to load templates: \(error.localizedDescription)")
            logger.error("Failed to load templates: \(error)")
        }
    }
    
    /// Create profile from template
    func createProfileFromTemplate(_ template: ProfileTemplate) {
        let profile = profileService.createProfileFromTemplate(template)
        profiles.append(profile)
        selectedProfile = profile
        saveProfile(profile)
        
        logger.info("Created profile from template: \(template.name)")
    }
    
    // MARK: - App Analysis
    
    /// Analyze dropped application
    func analyzeApplication(_ url: URL) {
        Task {
            await MainActor.run {
                isAnalyzing = true
            }
            
            // Simulate analysis delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // TODO: Implement actual app analysis
            let mockResult = AppAnalysisResult(
                bundleIdentifier: "com.example.app",
                displayName: "Example App",
                appPath: url.path,
                requiredPermissions: [.fullDiskAccess, .networkAccess],
                suggestedPayloads: [.privacyPreferences],
                appCategory: .productivity
            )
            
            await MainActor.run {
                analysisResults = [mockResult]
                isAnalyzing = false
            }
            
            logger.info("Analyzed application: \(url.lastPathComponent)")
        }
    }
    
    // MARK: - User Preferences
    
    @MainActor
    private func loadUserPreferences() async {
        // Load user preferences from UserDefaults
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        // Apply dark mode setting
        if isDarkMode {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else {
            NSApp.appearance = NSAppearance(named: .aqua)
        }
    }
    
    func updateDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        UserDefaults.standard.set(enabled, forKey: "isDarkMode")
        
        // Apply immediately
        if enabled {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else {
            NSApp.appearance = NSAppearance(named: .aqua)
        }
    }
    
    // MARK: - Error Handling
    
    func showError(_ message: String) {
        alertMessage = message
        showAlert = true
        logger.warning("Showing error to user: \(message)")
    }
    
    func clearError() {
        alertMessage = nil
        showAlert = false
    }
    
    // MARK: - Computed Properties
    
    var hasProfiles: Bool {
        !profiles.isEmpty
    }
    
    var canDeployToJAMF: Bool {
        isJAMFConnected && selectedProfile != nil
    }
    
    var jamfConnectionStatusText: String {
        if isJAMFConnected {
            if let serverInfo = jamfServerInfo {
                return "Connected to \(serverInfo.serverURL) (v\(serverInfo.version))"
            } else {
                return "Connected to JAMF Pro"
            }
        } else {
            return "Not connected"
        }
    }
}

// MARK: - Extensions for Missing Payload Support

extension AnyPayload {
    var dictionary: [String: Any] {
        switch payload {
        case let wifi as WiFiPayload:
            return wifi.dictionary
        case let vpn as VPNPayload:
            return vpn.dictionary
        default:
            // Return basic payload structure for unknown types
            return [
                "PayloadType": "unknown",
                "PayloadVersion": 1,
                "PayloadIdentifier": "unknown",
                "PayloadUUID": UUID().uuidString,
                "PayloadDisplayName": "Unknown Payload"
            ]
        }
    }
}

extension ConfigurationProfile {
    func exportToXML() throws -> Data {
        var profileDict: [String: Any] = [
            "PayloadType": payloadType,
            "PayloadVersion": payloadVersion,
            "PayloadIdentifier": payloadIdentifier,
            "PayloadUUID": payloadUUID,
            "PayloadDisplayName": payloadDisplayName,
            "PayloadDescription": payloadDescription,
            "PayloadOrganization": payloadOrganization,
            "PayloadScope": payloadScope.rawValue,
            "PayloadRemovalDisallowed": payloadRemovalDisallowed,
            "PayloadContent": payloadContent.map { $0.dictionary }
        ]
        
        // Add metadata with proper date formatting
        let dateFormatter = ISO8601DateFormatter()
        profileDict["PayloadCreationDate"] = dateFormatter.string(from: createdDate)
        profileDict["PayloadModificationDate"] = dateFormatter.string(from: modifiedDate)
        
        // Convert to property list format
        return try PropertyListSerialization.data(
            fromPropertyList: profileDict,
            format: .xml,
            options: 0
        )
    }
}

// MARK: - WiFiPayload Initialization Fix

extension WiFiPayload {
    init(payloadIdentifier: String, 
         payloadDisplayName: String, 
         SSID_STR: String, 
         hiddenNetwork: Bool = false, 
         autoJoin: Bool = true, 
         encryptionType: WiFiEncryption = .wpa2, 
         proxyType: ProxyType = .none) {
        
        self.payloadIdentifier = payloadIdentifier
        self.payloadDisplayName = payloadDisplayName
        self.SSID_STR = SSID_STR
        self.hiddenNetwork = hiddenNetwork
        self.autoJoin = autoJoin
        self.encryptionType = encryptionType
        self.proxyType = proxyType
        
        // Optional properties
        self.payloadDescription = nil
        self.payloadOrganization = nil
        self.password = nil
        self.proxyServer = nil
        self.proxyPort = nil
        self.proxyUsername = nil
        self.proxyPassword = nil
    }
}

// MARK: - VPNPayload Initialization Fix

extension VPNPayload {
    init(payloadIdentifier: String,
         payloadDisplayName: String,
         vpnType: VPNType,
         server: String,
         enableOnDemand: Bool = false,
         disconnectOnSleep: Bool = false) {
        
        self.payloadIdentifier = payloadIdentifier
        self.payloadDisplayName = payloadDisplayName
        self.vpnType = vpnType
        self.server = server
        self.enableOnDemand = enableOnDemand
        self.disconnectOnSleep = disconnectOnSleep
        
        // Optional properties
        self.payloadDescription = nil
        self.payloadOrganization = nil
        self.account = nil
        self.password = nil
        self.certificate = nil
    }
}

// MARK: - ScopeTargets Default Implementation

extension ScopeTargets: Codable {
    enum CodingKeys: String, CodingKey {
        case allComputers
        case computers
        case computerGroups
        case buildings
        case departments
        case exclusions
    }
    
    init() {
        self.allComputers = true
        self.computers = []
        self.computerGroups = []
        self.buildings = []
        self.departments = []
        self.exclusions = ScopeExclusions()
    }
}

extension ScopeExclusions: Codable {
    enum CodingKeys: String, CodingKey {
        case computers
        case computerGroups 
        case buildings
        case departments
    }
}