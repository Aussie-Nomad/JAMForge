// JAMForge/Features/ProfileBuilder/Services/JAMFAPIService.swift
import Foundation
import KeychainAccess
import Logging

/// Complete JAMF Pro API service with authentication and profile management
class JAMFAPIService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastError: JAMFError?
    @Published var serverInfo: JAMFServerInfo?
    
    // MARK: - Private Properties
    private var baseURL: URL
    private var currentToken: String?
    private var tokenExpiration: Date?
    private let keychain = Keychain(service: "com.jamforge.jamf")
    private let logger = Logger(label: "JAMFAPIService")
    private let session: URLSession
    
    // MARK: - Initialization
    init(baseURL: URL? = nil) {
        self.baseURL = baseURL ?? URL(string: "https://example.jamfcloud.com")!
        
        // Configure URL session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        // Try to load stored credentials
        loadStoredConnection()
    }
    
    // MARK: - Connection Management
    
    /// Connect to JAMF Pro server with credentials
    func connect(to serverURL: String, username: String, password: String) async throws {
        guard let url = URL(string: serverURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw JAMFError.invalidURL
        }
        
        await MainActor.run {
            self.connectionStatus = .connecting
            self.baseURL = url
        }
        
        do {
            // Test server connectivity first
            try await testServerConnectivity()
            
            // Attempt authentication
            let token = try await authenticateWithCredentials(username: username, password: password)
            
            // Store credentials securely
            try storeCredentials(serverURL: serverURL, username: username, password: password)
            
            // Get server information
            let serverInfo = try await getServerInfo()
            
            await MainActor.run {
                self.currentToken = token.token
                self.tokenExpiration = token.expires
                self.serverInfo = serverInfo
                self.isConnected = true
                self.connectionStatus = .connected
                self.lastError = nil
            }
            
            logger.info("Successfully connected to JAMF Pro: \(serverURL)")
            
        } catch let error as JAMFError {
            await MainActor.run {
                self.connectionStatus = .failed
                self.lastError = error
                self.isConnected = false
            }
            logger.error("Failed to connect to JAMF Pro: \(error)")
            throw error
        } catch {
            let jamfError = JAMFError.serverUnreachable
            await MainActor.run {
                self.connectionStatus = .failed
                self.lastError = jamfError
                self.isConnected = false
            }
            logger.error("Unexpected error connecting to JAMF Pro: \(error)")
            throw jamfError
        }
    }
    
    /// Disconnect from JAMF Pro
    func disconnect() async {
        if let token = currentToken {
            try? await invalidateToken(token)
        }
        
        await MainActor.run {
            self.currentToken = nil
            self.tokenExpiration = nil
            self.serverInfo = nil
            self.isConnected = false
            self.connectionStatus = .disconnected
            self.lastError = nil
        }
        
        // Clear stored credentials
        clearStoredCredentials()
        
        logger.info("Disconnected from JAMF Pro")
    }
    
    // MARK: - Authentication
    
    /// Authenticate with username and password to get bearer token
    private func authenticateWithCredentials(username: String, password: String) async throws -> AuthResponse {
        let authURL = baseURL.appendingPathComponent("/api/v1/auth/token")
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add basic auth header
        let authString = "\(username):\(password)"
        guard let authData = authString.data(using: .utf8) else {
            throw JAMFError.authenticationFailed(400)
        }
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JAMFError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                logger.info("Successfully authenticated with JAMF Pro")
                return authResponse
                
            case 401:
                logger.warning("Authentication failed - invalid credentials")
                throw JAMFError.authenticationFailed(401)
                
            case 403:
                logger.warning("Authentication failed - insufficient privileges")
                throw JAMFError.authenticationFailed(403)
                
            default:
                logger.error("Authentication failed with status: \(httpResponse.statusCode)")
                throw JAMFError.authenticationFailed(httpResponse.statusCode)
            }
            
        } catch let error as JAMFError {
            throw error
        } catch {
            logger.error("Network error during authentication: \(error)")
            throw JAMFError.serverUnreachable
        }
    }
    
    /// Refresh the current bearer token
    func refreshToken() async throws {
        guard let currentToken = currentToken else {
            throw JAMFError.notConnected
        }
        
        let refreshURL = baseURL.appendingPathComponent("/api/v1/auth/keep-alive")
        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(currentToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JAMFError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                await MainActor.run {
                    self.currentToken = authResponse.token
                    self.tokenExpiration = authResponse.expires
                }
                logger.info("Successfully refreshed JAMF Pro token")
                
            case 401:
                logger.warning("Token refresh failed - token expired")
                await MainActor.run {
                    self.connectionStatus = .failed
                    self.isConnected = false
                }
                throw JAMFError.tokenExpired
                
            default:
                logger.error("Token refresh failed with status: \(httpResponse.statusCode)")
                throw JAMFError.tokenRefreshFailed
            }
            
        } catch let error as JAMFError {
            throw error
        } catch {
            logger.error("Network error during token refresh: \(error)")
            throw JAMFError.serverUnreachable
        }
    }
    
    /// Invalidate the current bearer token
    private func invalidateToken(_ token: String) async throws {
        let invalidateURL = baseURL.appendingPathComponent("/api/v1/auth/invalidate-token")
        var request = URLRequest(url: invalidateURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 204 {
                    logger.info("Successfully invalidated JAMF Pro token")
                } else {
                    logger.warning("Token invalidation returned status: \(httpResponse.statusCode)")
                }
            }
        } catch {
            logger.warning("Failed to invalidate token: \(error)")
            // Don't throw error as this is cleanup
        }
    }
    
    // MARK: - Server Information
    
    /// Get JAMF Pro server information
    private func getServerInfo() async throws -> JAMFServerInfo {
        guard let token = currentToken else {
            throw JAMFError.notConnected
        }
        
        let infoURL = baseURL.appendingPathComponent("/api/v1/jamf-pro-version")
        var request = URLRequest(url: infoURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JAMFError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let versionInfo = try JSONDecoder().decode(JAMFVersionInfo.self, from: data)
                return JAMFServerInfo(
                    serverURL: baseURL.absoluteString,
                    version: versionInfo.version,
                    buildDate: versionInfo.buildDate
                )
            } else {
                throw JAMFError.requestFailed
            }
            
        } catch let error as JAMFError {
            throw error
        } catch {
            logger.error("Failed to get server info: \(error)")
            throw JAMFError.requestFailed
        }
    }
    
    /// Test server connectivity
    private func testServerConnectivity() async throws {
        let healthURL = baseURL.appendingPathComponent("/healthCheck.html")
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JAMFError.serverUnreachable
            }
            
            if httpResponse.statusCode != 200 {
                logger.warning("Server health check returned status: \(httpResponse.statusCode)")
            }
            
        } catch {
            logger.error("Server connectivity test failed: \(error)")
            throw JAMFError.serverUnreachable
        }
    }
    
    // MARK: - Profile Management
    
    /// Upload a configuration profile to JAMF Pro
    func uploadProfile(_ profile: ConfigurationProfile) async throws -> JAMFProfileResponse {
        try await ensureValidToken()
        
        guard let token = currentToken else {
            throw JAMFError.notConnected
        }
        
        let uploadURL = baseURL.appendingPathComponent("/api/v1/os-x-configuration-profiles")
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Create the profile upload payload
        let uploadPayload = JAMFProfileUpload(
            general: JAMFProfileGeneral(
                name: profile.payloadDisplayName,
                description: profile.payloadDescription,
                level: profile.payloadScope == .user ? "User" : "System",
                payloads: try profile.exportToXML().base64EncodedString()
            )
        )
        
        do {
            let jsonData = try JSONEncoder().encode(uploadPayload)
            request.httpBody = jsonData
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JAMFError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 201:
                let profileResponse = try JSONDecoder().decode(JAMFProfileResponse.self, from: data)
                logger.info("Successfully uploaded profile: \(profile.payloadDisplayName) (ID: \(profileResponse.id))")
                return profileResponse
                
            case 401:
                throw JAMFError.tokenExpired
                
            case 400:
                logger.error("Profile upload failed - bad request")
                throw JAMFError.uploadFailed(400)
                
            case 409:
                logger.error("Profile upload failed - conflict (profile may already exist)")
                throw JAMFError.uploadFailed(409)
                
            default:
                logger.error("Profile upload failed with status: \(httpResponse.statusCode)")
                throw JAMFError.uploadFailed(httpResponse.statusCode)
            }
            
        } catch let error as JAMFError {
            throw error
        } catch {
            logger.error("Network error during profile upload: \(error)")
            throw JAMFError.requestFailed
        }
    }
    
    /// Get all configuration profiles from JAMF Pro
    func getProfiles() async throws -> [JAMFProfile] {
        try await ensureValidToken()
        
        guard let token = currentToken else {
            throw JAMFError.notConnected
        }
        
        let profilesURL = baseURL.appendingPathComponent("/api/v1/os-x-configuration-profiles")
        var request = URLRequest(url: profilesURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JAMFError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let profilesResponse = try JSONDecoder().decode(JAMFProfilesResponse.self, from: data)
                logger.info("Retrieved \(profilesResponse.results.count) profiles from JAMF Pro")
                return profilesResponse.results
            } else {
                throw JAMFError.requestFailed
            }
            
        } catch let error as JAMFError {
            throw error
        } catch {
            logger.error("Failed to get profiles: \(error)")
            throw JAMFError.requestFailed
        }
    }
    
    /// Update profile scope in JAMF Pro
    func updateProfileScope(profileId: Int, scope: ScopeTargets) async throws {
        try await ensureValidToken()
        
        guard let token = currentToken else {
            throw JAMFError.notConnected
        }
        
        let scopeURL = baseURL.appendingPathComponent("/api/v1/os-x-configuration-profiles/\(profileId)")
        var request = URLRequest(url: scopeURL)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let scopeData = try JSONEncoder().encode(scope)
            request.httpBody = scopeData
            
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JAMFError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                logger.info("Successfully updated scope for profile: \(profileId)")
            } else {
                logger.error("Failed to update scope for profile \(profileId): \(httpResponse.statusCode)")
                throw JAMFError.scopeAssignmentFailed
            }
            
        } catch let error as JAMFError {
            throw error
        } catch {
            logger.error("Failed to update profile scope: \(error)")
            throw JAMFError.scopeAssignmentFailed
        }
    }
    
    /// Delete a configuration profile from JAMF Pro
    func deleteProfile(id: Int) async throws {
        try await ensureValidToken()
        
        guard let token = currentToken else {
            throw JAMFError.notConnected
        }
        
        let deleteURL = baseURL.appendingPathComponent("/api/v1/os-x-configuration-profiles/\(id)")
        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JAMFError.invalidResponse
            }
            
            if httpResponse.statusCode == 204 {
                logger.info("Successfully deleted profile: \(id)")
            } else {
                logger.error("Failed to delete profile \(id): \(httpResponse.statusCode)")
                throw JAMFError.deleteFailed
            }
            
        } catch let error as JAMFError {
            throw error
        } catch {
            logger.error("Failed to delete profile: \(error)")
            throw JAMFError.deleteFailed
        }
    }
    
    // MARK: - Token Management
    
    /// Ensure we have a valid token, refreshing if necessary
    private func ensureValidToken() async throws {
        guard let expiration = tokenExpiration else {
            throw JAMFError.notConnected
        }
        
        // Refresh token if it expires within 5 minutes
        let fiveMinutesFromNow = Date().addingTimeInterval(300)
        if expiration <= fiveMinutesFromNow {
            try await refreshToken()
        }
    }
    
    /// Check if current token is valid
    var isTokenValid: Bool {
        guard let expiration = tokenExpiration else { return false }
        return Date() < expiration
    }
    
    // MARK: - Credential Storage
    
    /// Store credentials securely in Keychain
    private func storeCredentials(serverURL: String, username: String, password: String) throws {
        do {
            try keychain.set(serverURL, key: "serverURL")
            try keychain.set(username, key: "username")
            try keychain.set(password, key: "password")
            logger.info("Stored JAMF Pro credentials in Keychain")
        } catch {
            logger.error("Failed to store credentials: \(error)")
            throw JAMFError.keychainError
        }
    }
    
    /// Load stored credentials from Keychain
    func loadStoredCredentials() -> (server: String, username: String, password: String)? {
        do {
            guard let serverURL = try keychain.get("serverURL"),
                  let username = try keychain.get("username"),
                  let password = try keychain.get("password") else {
                return nil
            }
            return (serverURL, username, password)
        } catch {
            logger.error("Failed to load stored credentials: \(error)")
            return nil
        }
    }
    
    /// Clear stored credentials from Keychain
    private func clearStoredCredentials() {
        do {
            try keychain.remove("serverURL")
            try keychain.remove("username")
            try keychain.remove("password")
            logger.info("Cleared stored JAMF Pro credentials")
        } catch {
            logger.warning("Failed to clear stored credentials: \(error)")
        }
    }
    
    /// Load stored connection and attempt auto-connect
    private func loadStoredConnection() {
        guard let credentials = loadStoredCredentials() else {
            logger.info("No stored JAMF Pro credentials found")
            return
        }
        
        Task {
            do {
                try await connect(
                    to: credentials.server,
                    username: credentials.username,
                    password: credentials.password
                )
            } catch {
                logger.warning("Failed to auto-connect with stored credentials: \(error)")
            }
        }
    }
}

// MARK: - Supporting Data Models

struct JAMFProfileUpload: Codable {
    let general: JAMFProfileGeneral
}

struct JAMFProfileGeneral: Codable {
    let name: String
    let description: String
    let level: String
    let payloads: String
}

struct JAMFVersionInfo: Codable {
    let version: String
    let buildDate: String?
    
    private enum CodingKeys: String, CodingKey {
        case version
        case buildDate = "build-date"
    }
}

struct JAMFServerInfo {
    let serverURL: String
    let version: String
    let buildDate: String?
}

// Updated JAMFProfilesResponse to match API
struct JAMFProfilesResponse: Codable {
    let totalCount: Int
    let results: [JAMFProfile]
}

// Updated JAMFProfile to match API response
extension JAMFProfile {
    private enum CodingKeys: String, CodingKey {
        case id, name, description, level
        case deploymentMethod = "distributionMethod"
    }
}

// MARK: - Connection Status Extensions

extension ConnectionStatus {
    var icon: String {
        switch self {
        case .disconnected: return "circle"
        case .connecting: return "circle.dotted"
        case .connected: return "circle.fill"
        case .failed: return "exclamationmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .secondary
        case .connecting: return .orange
        case .connected: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Enhanced JAMFConnectionView Updates

struct ScopeConfigurationView: View {
    @Binding var selectedScope: ProfileScope
    @Binding var scopeTargets: ScopeTargets
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Deployment Scope")
                .font(.headline)
            
            Picker("Scope", selection: $selectedScope) {
                Text("User Level").tag(ProfileScope.user)
                Text("System Level").tag(ProfileScope.system)
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Deploy to All Computers", isOn: $scopeTargets.allComputers)
                
                if !scopeTargets.allComputers {
                    Text("Specific Targeting")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // TODO: Add specific computer/group selection
                    Text("Specific targeting options coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct DeploymentOptionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deployment Options")
                .font(.headline)
            
            Toggle("Make Profile Removable", isOn: .constant(true))
            Toggle("Show in Self Service", isOn: .constant(false))
            Toggle("Install Automatically", isOn: .constant(true))
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Error Extensions

extension JAMFError {
    var title: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .notConnected:
            return "Not Connected"
        case .authenticationFailed:
            return "Authentication Failed"
        case .serverUnreachable:
            return "Server Unreachable"
        case .uploadFailed:
            return "Upload Failed"
        case .tokenExpired:
            return "Session Expired"
        default:
            return "Error"
        }
    }
    
    var recoverySuggestion: String {
        switch self {
        case .invalidURL:
            return "Please check the server URL format."
        case .authenticationFailed:
            return "Please verify your username and password."
        case .serverUnreachable:
            return "Please check your network connection and server URL."
        case .tokenExpired:
            return "Please reconnect to JAMF Pro."
        case .uploadFailed:
            return "Please check the profile format and try again."
        default:
            return "Please try again or contact support."
        }
    }
}