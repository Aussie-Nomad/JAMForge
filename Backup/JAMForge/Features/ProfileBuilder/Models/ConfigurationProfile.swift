import Foundation
import SwiftUI

struct ConfigurationProfile: Identifiable, Codable {
    let id = UUID()
    var payloadContent: [AnyPayload] = []
    var payloadDescription: String = ""
    var payloadDisplayName: String = "New Profile"
    var payloadIdentifier: String
    var payloadOrganization: String = ""
    var payloadUUID: String = UUID().uuidString.uppercased()
    var payloadType: String = "Configuration"
    var payloadVersion: Int = 1
    var payloadScope: ProfileScope = .user
    var payloadRemovalDisallowed: Bool = false
    
    // Metadata
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()
    var version: String = "1.0"
    var tags: [String] = []
    
    init(name: String, identifier: String? = nil) {
        self.payloadDisplayName = name
        self.payloadIdentifier = identifier ?? "com.company.\(name.lowercased().replacingOccurrences(of: " ", with: ""))"
    }
}

enum ProfileScope: String, CaseIterable, Codable {
    case user = "User"
    case system = "System"
}

protocol Payload: Identifiable, Codable {
    var id: UUID { get }
    var payloadType: String { get }
    var payloadVersion: Int { get }
    var payloadIdentifier: String { get }
    var payloadUUID: String { get }
    var payloadDisplayName: String { get }
    var payloadDescription: String { get }
    var payloadOrganization: String { get }
    
    static var displayName: String { get }
    static var icon: String { get }
    static var category: PayloadCategory { get }
    static var requiredPermissions: [PrivacyPermission] { get }
}

enum PayloadCategory: String, CaseIterable {
    case network = "Network"
    case security = "Security"
    case restrictions = "Restrictions"
    case accounts = "Accounts"
    case device = "Device Management"
    case privacy = "Privacy & Permissions"
}

enum PayloadType: String, CaseIterable {
    case wifi = "com.apple.wifi.managed"
    case vpn = "com.apple.vpn.managed"
    case certificate = "com.apple.security.pkcs12"
    case restrictions = "com.apple.applicationaccess"
    case privacyPreferences = "com.apple.TCC.configuration-profile-policy"
    case systemPolicy = "com.apple.systempolicy.control"
    case email = "com.apple.mail.managed"
    case exchange = "com.apple.eas.account"
}

// Type erasure wrapper for payloads
struct AnyPayload: Codable, Identifiable {
    let id: UUID
    let payload: Any
    
    private enum CodingKeys: String, CodingKey {
        case id, type, payload
    }
    
    init<P: Payload>(_ payload: P) {
        self.id = payload.id
        self.payload = payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        let type = try container.decode(String.self, forKey: .type)
        
        // Decode based on type
        switch type {
        case PayloadType.wifi.rawValue:
            self.payload = try container.decode(WiFiPayload.self, forKey: .payload)
        case PayloadType.vpn.rawValue:
            self.payload = try container.decode(VPNPayload.self, forKey: .payload)
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown payload type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        
        switch payload {
        case let wifi as WiFiPayload:
            try container.encode(PayloadType.wifi.rawValue, forKey: .type)
            try container.encode(wifi, forKey: .payload)
        case let vpn as VPNPayload:
            try container.encode(PayloadType.vpn.rawValue, forKey: .type)
            try container.encode(vpn, forKey: .payload)
        default:
            throw EncodingError.invalidValue(payload, .init(codingPath: encoder.codingPath, debugDescription: "Unknown payload type"))
        }
    }
}
