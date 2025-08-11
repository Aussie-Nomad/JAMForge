# API Documentation

## Core APIs

### Profile Management

#### ProfileService

```swift
class ProfileService {
    // Create a new configuration profile
    func createProfile(name: String, identifier: String, organization: String) -> ConfigurationProfile
    
    // Save profile to disk
    func saveProfile(_ profile: ConfigurationProfile) throws
    
    // Load profile from disk
    func loadProfile(from url: URL) throws -> ConfigurationProfile
    
    // Export profile as .mobileconfig
    func exportProfile(_ profile: ConfigurationProfile, to url: URL) throws
    
    // Sign profile with certificate
    func signProfile(_ profile: ConfigurationProfile, with certificate: SecIdentity) throws -> Data
}
```

#### JAMFAPIService

```swift
class JAMFAPIService {
    // Authentication
    func authenticate(username: String, password: String) async throws -> String
    func refreshToken() async throws -> String
    
    // Profile Management
    func uploadProfile(_ profile: ConfigurationProfile) async throws -> Int
    func updateProfile(id: Int, profile: ConfigurationProfile) async throws
    func deleteProfile(id: Int) async throws
    func getProfiles() async throws -> [JAMFProfile]
    
    // Scope Management
    func getScope(for profileId: Int) async throws -> ProfileScope
    func updateScope(_ scope: ProfileScope, for profileId: Int) async throws
}
```

### Security

#### SecurityManager

```swift
class SecurityManager {
    // Credential Management
    func storeCredentials(_ credentials: Credentials, for service: String) throws
    func retrieveCredentials(for service: String) throws -> Credentials?
    
    // Profile Security
    func signProfile(_ data: Data, with certificate: SecIdentity) throws -> Data
    func validateProfile(_ data: Data) throws -> Bool
    func encryptProfile(_ data: Data, for recipients: [SecCertificate]) throws -> Data
}
```

## Data Models

### ConfigurationProfile

```swift
struct ConfigurationProfile: Codable {
    var payloadContent: [Payload]
    var payloadDescription: String?
    var payloadDisplayName: String
    var payloadIdentifier: String
    var payloadOrganization: String?
    var payloadUUID: String
    var payloadType: String
    var payloadVersion: Int
    var payloadScope: String
    
    func validate() throws -> Bool
    func addPayload(_ payload: Payload) throws
    func removePayload(at index: Int)
    func generateXML() throws -> Data
}
```

### Payload Types

```swift
protocol Payload: Codable {
    var payloadType: String { get }
    var payloadVersion: Int { get }
    var payloadIdentifier: String { get }
    var payloadUUID: String { get }
    var payloadDisplayName: String { get }
    var payloadDescription: String? { get }
    var payloadOrganization: String? { get }
}

struct WiFiPayload: Payload {
    // Wi-Fi specific properties
}

struct VPNPayload: Payload {
    // VPN specific properties
}

struct CertificatePayload: Payload {
    // Certificate specific properties
}
```

## Integration Examples

### Creating and Uploading a Profile

```swift
// Create a new profile
let profileService = ProfileService()
let profile = profileService.createProfile(
    name: "WiFi Configuration",
    identifier: "com.organization.wifi",
    organization: "My Organization"
)

// Add Wi-Fi payload
let wifiPayload = WiFiPayload(
    ssid: "Corporate Network",
    security: .wpa2Enterprise,
    username: "{{username}}"
)
try profile.addPayload(wifiPayload)

// Sign the profile
let securityManager = SecurityManager()
let signedData = try securityManager.signProfile(profile.generateXML(), with: certificate)

// Upload to JAMF
let jamfService = JAMFAPIService()
try await jamfService.authenticate(username: "admin", password: "password")
let profileId = try await jamfService.uploadProfile(signedData)

// Set scope
let scope = ProfileScope(
    computers: ["All Computers"],
    computerGroups: ["Development Macs"]
)
try await jamfService.updateScope(scope, for: profileId)
```

## Error Handling

```swift
enum ProfileError: Error {
    case invalidPayload(String)
    case signatureError(String)
    case validationError(String)
    case exportError(String)
}

enum JAMFError: Error {
    case authenticationFailed
    case connectionError(String)
    case resourceNotFound
    case invalidResponse(String)
}

enum SecurityError: Error {
    case certificateNotFound
    case keychainError(String)
    case encryptionError(String)
}
```

## Best Practices

1. **Error Handling**
   - Always wrap API calls in try-catch blocks
   - Provide meaningful error messages
   - Log errors appropriately

2. **Security**
   - Store credentials securely in Keychain
   - Always sign profiles before deployment
   - Validate certificates before use

3. **Performance**
   - Use async/await for network operations
   - Cache frequently used data
   - Batch profile operations when possible

4. **Validation**
   - Validate profiles before saving
   - Verify payload compatibility
   - Check for required fields
