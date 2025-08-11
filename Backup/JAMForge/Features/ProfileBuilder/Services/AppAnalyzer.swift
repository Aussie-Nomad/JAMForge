import Foundation

class AppAnalyzer: ObservableObject {
    func analyzeApp(at url: URL) -> AppAnalysisResult? {
        guard let bundle = Bundle(url: url) else { return nil }
        
        let bundleIdentifier = bundle.bundleIdentifier ?? "unknown"
        let displayName = bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                         bundle.infoDictionary?["CFBundleName"] as? String ??
                         url.lastPathComponent
        
        let requiredPermissions = determineRequiredPermissions(for: bundleIdentifier, bundle: bundle)
        let suggestedPayloads = generateSuggestedPayloads(for: bundleIdentifier, permissions: requiredPermissions)
        
        return AppAnalysisResult(
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            appPath: url.path,
            requiredPermissions: requiredPermissions,
            suggestedPayloads: suggestedPayloads,
            appCategory: categorizeApp(bundleIdentifier)
        )
    }
    
    private func determineRequiredPermissions(for bundleIdentifier: String, bundle: Bundle) -> [PrivacyPermission] {
        var permissions: [PrivacyPermission] = []
        
        // Check for common security software patterns
        if isSecuritySoftware(bundleIdentifier) {
            permissions.append(contentsOf: [.fullDiskAccess, .systemPolicyControl, .privacyPreferences])
        }
        
        // Check for network usage
        if hasNetworkUsage(bundle) {
            permissions.append(.networkAccess)
        }
        
        // Check entitlements for specific permissions
        if let entitlements = bundle.object(forInfoDictionaryKey: "com.apple.security.app-sandbox") {
            permissions.append(contentsOf: parseEntitlements(entitlements))
        }
        
        return Array(Set(permissions)) // Remove duplicates
    }
    
    private func isSecuritySoftware(_ bundleId: String) -> Bool {
        let securityPatterns = [
            "antivirus", "security", "endpoint", "crowdstrike", "sentinelone",
            "bitdefender", "symantec", "mcafee", "kaspersky", "eset"
        ]
        return securityPatterns.contains { bundleId.lowercased().contains($0) }
    }
    
    private func hasNetworkUsage(_ bundle: Bundle) -> Bool {
        // TODO: Check for network-related entitlements or permissions
        return true
    }
    
    private func parseEntitlements(_ entitlements: Any) -> [PrivacyPermission] {
        // TODO: Parse actual entitlements to determine permissions
        return []
    }
    
    private func generateSuggestedPayloads(for bundleId: String, permissions: [PrivacyPermission]) -> [PayloadType] {
        var payloads: [PayloadType] = []
        
        if permissions.contains(.fullDiskAccess) || permissions.contains(.systemPolicyControl) {
            payloads.append(.privacyPreferences)
        }
        
        if permissions.contains(.networkAccess) {
            payloads.append(.systemPolicy)
        }
        
        return payloads
    }
    
    private func categorizeApp(_ bundleId: String) -> AppCategory {
        if isSecuritySoftware(bundleId) { return .security }
        if bundleId.contains("vpn") { return .network }
        return .productivity
    }
}

struct AppAnalysisResult {
    let bundleIdentifier: String
    let displayName: String
    let appPath: String
    let requiredPermissions: [PrivacyPermission]
    let suggestedPayloads: [PayloadType]
    let appCategory: AppCategory
}

enum AppCategory: String, CaseIterable {
    case security = "Security"
    case network = "Network"
    case productivity = "Productivity"
    case development = "Development"
    case multimedia = "Multimedia"
    case utilities = "Utilities"
}
