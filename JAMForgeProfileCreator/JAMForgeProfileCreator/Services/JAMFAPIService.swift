import Foundation

class JAMFAPIService: ObservableObject {
    private var baseURL: URL
    private var tokenManager: TokenManager
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastError: JAMFError?
    
    init() {
        self.baseURL = URL(string: "https://example.jamfcloud.com")!
        self.tokenManager = TokenManager()
    }
    
    func connect(to serverURL: String, username: String, password: String) async throws {
        guard let url = URL(string: serverURL) else {
            throw JAMFError.invalidURL
        }
        
        self.baseURL = url
        
        // Attempt authentication
        let authURL = baseURL.appendingPathComponent("/api/v1/auth/token")
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        
        // Add basic auth header
        let authString = "\(username):\(password)"
        let authData = authString.data(using: .utf8)!
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            try tokenManager.storeToken(authResponse.token)
            await MainActor.run {
                self.isConnected = true
                self.connectionStatus = .connected
            }
        case 401:
            throw JAMFError.authenticationFailed(401)
        default:
            throw JAMFError.authenticationFailed(httpResponse.statusCode)
        }
    }
    
    func uploadProfile(_ profile: ConfigurationProfile) async throws -> JAMFProfileResponse {
        guard let token = try? tokenManager.retrieveToken() else {
            throw JAMFError.notConnected
        }
        
        let uploadURL = baseURL.appendingPathComponent("/api/v1/osxconfigurationprofiles")
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        
        // Convert profile to XML
        let profileData = try profile.exportToXML()
        request.httpBody = profileData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 201:
            return try JSONDecoder().decode(JAMFProfileResponse.self, from: data)
        case 401:
            throw JAMFError.tokenExpired
        default:
            throw JAMFError.uploadFailed(httpResponse.statusCode)
        }
    }
    
    func assignScope(profileId: Int, scope: ProfileScope, targets: ScopeTargets) async throws {
        guard let token = try? tokenManager.retrieveToken() else {
            throw JAMFError.notConnected
        }
        
        let scopeURL = baseURL.appendingPathComponent("/api/v1/osxconfigurationprofiles/\(profileId)/scope")
        var request = URLRequest(url: scopeURL)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert scope to JSON
        let scopeData = try JSONEncoder().encode(targets)
        request.httpBody = scopeData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JAMFError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw JAMFError.scopeAssignmentFailed
        }
    }
    
    func loadStoredCredentials() -> (server: String, username: String, password: String)? {
        // TODO: Implement Keychain retrieval
        return nil
    }
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case failed
    
    var description: String {
        switch self {
        case .disconnected:
            return "Not connected to JAMF Pro"
        case .connecting:
            return "Connecting to JAMF Pro..."
        case .connected:
            return "Connected to JAMF Pro"
        case .failed:
            return "Connection failed"
        }
    }
}

private class TokenManager {
    private let keychainService = "com.jamforge.jamftoken"
    
    func storeToken(_ token: String) throws {
        // TODO: Implement secure token storage in Keychain
    }
    
    func retrieveToken() throws -> String {
        // TODO: Implement token retrieval from Keychain
        throw JAMFError.keychainError
    }
}
