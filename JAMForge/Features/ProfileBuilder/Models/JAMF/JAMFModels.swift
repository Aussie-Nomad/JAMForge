import Foundation

struct AuthResponse: Codable {
    let token: String
    let expires: Date
}

struct JAMFProfile: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let level: String
    let deploymentMethod: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, level
        case deploymentMethod = "distribution_method"
    }
}

struct JAMFProfileResponse: Codable {
    let id: Int
    let name: String
}

struct JAMFProfilesResponse: Codable {
    let profiles: [JAMFProfile]
    
    private enum CodingKeys: String, CodingKey {
        case profiles = "configuration_profiles"
    }
}

struct ScopeTargets {
    var allComputers: Bool = false
    var computers: [JAMFComputer] = []
    var computerGroups: [JAMFComputerGroup] = []
    var buildings: [JAMFBuilding] = []
    var departments: [JAMFDepartment] = []
    var exclusions: ScopeExclusions = ScopeExclusions()
}

struct ScopeExclusions {
    var computers: [JAMFComputer] = []
    var computerGroups: [JAMFComputerGroup] = []
    var buildings: [JAMFBuilding] = []
    var departments: [JAMFDepartment] = []
}

struct JAMFComputer: Identifiable, Codable {
    let id: Int
    let name: String
    let udid: String?
    let serialNumber: String?
}

struct JAMFComputerGroup: Identifiable, Codable {
    let id: Int
    let name: String
    let isSmart: Bool
}

struct JAMFBuilding: Identifiable, Codable {
    let id: Int
    let name: String
}

struct JAMFDepartment: Identifiable, Codable {
    let id: Int
    let name: String
}

enum JAMFError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case invalidResponse
    case authenticationFailed(Int)
    case serverUnreachable
    case uploadFailed(Int)
    case requestFailed
    case deleteFailed
    case scopeAssignmentFailed
    case tokenExpired
    case tokenRefreshFailed
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid JAMF Pro server URL"
        case .notConnected:
            return "Not connected to JAMF Pro server"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed(let code):
            return "Authentication failed (HTTP \(code))"
        case .serverUnreachable:
            return "JAMF Pro server is unreachable"
        case .uploadFailed(let code):
            return "Profile upload failed (HTTP \(code))"
        case .requestFailed:
            return "Request failed"
        case .deleteFailed:
            return "Profile deletion failed"
        case .scopeAssignmentFailed:
            return "Scope assignment failed"
        case .tokenExpired:
            return "Authentication token expired"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .keychainError:
            return "Keychain access error"
        }
    }
}
