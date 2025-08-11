import Foundation

struct ProfileTemplate: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var category: TemplateCategory
    var payloads: [AnyPayload]
    var requiredPermissions: [PrivacyPermission]
    var suggestedApps: [String] // Bundle identifiers
    var tags: [String]
    var author: String
    var version: String
    var isBuiltIn: Bool
    
    static let antivirusTemplate = ProfileTemplate(
        name: "Antivirus Software",
        description: "Complete security permissions for antivirus applications",
        category: .security,
        payloads: [],
        requiredPermissions: [.fullDiskAccess, .systemPolicyControl, .privacyPreferences, .networkAccess],
        suggestedApps: ["com.bitdefender.endpoint-security-for-mac", "com.eset.remoteadministrator.agent"],
        tags: ["security", "antivirus", "endpoint"],
        author: "JAMForge",
        version: "1.0",
        isBuiltIn: true
    )
    
    static let vpnTemplate = ProfileTemplate(
        name: "VPN Configuration",
        description: "Standard VPN setup with network permissions",
        category: .network,
        payloads: [],
        requiredPermissions: [.networkAccess, .systemPolicyControl],
        suggestedApps: [],
        tags: ["vpn", "network", "security"],
        author: "JAMForge",
        version: "1.0",
        isBuiltIn: true
    )
}

enum TemplateCategory: String, CaseIterable {
    case security = "Security"
    case network = "Network"
    case productivity = "Productivity"
    case education = "Education"
    case enterprise = "Enterprise"
    case custom = "Custom"
}
