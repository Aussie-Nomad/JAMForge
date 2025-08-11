// JAMForge/Features/ProfileBuilder/Services/ProfileService.swift
import Foundation
import Security
import CryptoKit
import XMLCoder
import Logging

/// Service responsible for profile management, including creation, signing, and encryption
class ProfileService: ObservableObject {
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = Logger(label: "ProfileService")
    
    enum ProfileServiceError: Error, LocalizedError {
        case profileNotFound
        case invalidProfileData
        case saveError(String)
        case loadError(String)
        case exportError(String)
        case signingError(String)
        case validationError([String])
        
        var errorDescription: String? {
            switch self {
            case .profileNotFound:
                return "Profile not found"
            case .invalidProfileData:
                return "Invalid profile data"
            case .saveError(let message):
                return "Failed to save profile: \(message)"
            case .loadError(let message):
                return "Failed to load profile: \(message)"
            case .exportError(let message):
                return "Failed to export profile: \(message)"
            case .signingError(let message):
                return "Failed to sign profile: \(message)"
            case .validationError(let errors):
                return "Profile validation failed: \(errors.joined(separator: ", "))"
            }
        }
    }
    
    // MARK: - File Paths
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var profilesDirectory: URL {
        documentsDirectory.appendingPathComponent("JAMForge/Profiles")
    }
    
    private var templatesDirectory: URL {
        documentsDirectory.appendingPathComponent("JAMForge/Templates")
    }
    
    // MARK: - Initialization
    init() {
        setupDirectories()
        configureEncoder()
    }
    
    private func setupDirectories() {
        do {
            try fileManager.createDirectory(at: profilesDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: templatesDirectory, withIntermediateDirectories: true)
            logger.info("Created JAMForge directories")
        } catch {
            logger.error("Failed to create directories: \(error)")
        }
    }
    
    private func configureEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Profile Management
    
    /// Create a new configuration profile
    func createProfile(name: String, identifier: String? = nil, organization: String = "") -> ConfigurationProfile {
        let profileIdentifier = identifier ?? "com.company.\(name.lowercased().replacingOccurrences(of: " ", with: ""))"
        
        var profile = ConfigurationProfile(name: name, identifier: profileIdentifier)
        profile.payloadOrganization = organization
        profile.createdDate = Date()
        profile.modifiedDate = Date()
        
        logger.info("Created new profile: \(name) (\(profileIdentifier))")
        return profile
    }
    
    /// Load all profiles from disk
    func loadAllProfiles() throws -> [ConfigurationProfile] {
        guard fileManager.fileExists(atPath: profilesDirectory.path) else {
            logger.info("Profiles directory doesn't exist, returning empty array")
            return []
        }
        
        do {
            let profileFiles = try fileManager.contentsOfDirectory(at: profilesDirectory, 
                                                                 includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "jamfprofile" }
            
            var profiles: [ConfigurationProfile] = []
            
            for file in profileFiles {
                do {
                    let profile = try loadProfile(from: file)
                    profiles.append(profile)
                } catch {
                    logger.warning("Failed to load profile from \(file.lastPathComponent): \(error)")
                    // Continue loading other profiles even if one fails
                }
            }
            
            logger.info("Loaded \(profiles.count) profiles")
            return profiles.sorted { $0.modifiedDate > $1.modifiedDate }
            
        } catch {
            logger.error("Failed to load profiles: \(error)")
            throw ProfileServiceError.loadError(error.localizedDescription)
        }
    }
    
    /// Load a specific profile from disk
    func loadProfile(from url: URL) throws -> ConfigurationProfile {
        do {
            let data = try Data(contentsOf: url)
            var profile = try decoder.decode(ConfigurationProfile.self, from: data)
            
            // Update file path for future saves
            profile.filePath = url
            
            logger.info("Loaded profile: \(profile.payloadDisplayName)")
            return profile
            
        } catch {
            logger.error("Failed to load profile from \(url.path): \(error)")
            throw ProfileServiceError.loadError(error.localizedDescription)
        }
    }
    
    /// Save profile to disk
    func saveProfile(_ profile: ConfigurationProfile) throws {
        var updatedProfile = profile
        updatedProfile.modifiedDate = Date()
        
        // Validate profile before saving
        try validateProfile(updatedProfile)
        
        let fileName = "\(sanitizeFileName(updatedProfile.payloadDisplayName)).jamfprofile"
        let fileURL = profilesDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try encoder.encode(updatedProfile)
            try data.write(to: fileURL)
            
            logger.info("Saved profile: \(updatedProfile.payloadDisplayName) to \(fileName)")
            
        } catch {
            logger.error("Failed to save profile: \(error)")
            throw ProfileServiceError.saveError(error.localizedDescription)
        }
    }
    
    /// Delete profile from disk
    func deleteProfile(_ profile: ConfigurationProfile) throws {
        let fileName = "\(sanitizeFileName(profile.payloadDisplayName)).jamfprofile"
        let fileURL = profilesDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            logger.info("Deleted profile: \(profile.payloadDisplayName)")
        } catch {
            logger.error("Failed to delete profile: \(error)")
            throw ProfileServiceError.saveError(error.localizedDescription)
        }
    }
    
    /// Duplicate an existing profile
    func duplicateProfile(_ profile: ConfigurationProfile) -> ConfigurationProfile {
        var newProfile = profile
        newProfile.id = UUID()
        newProfile.payloadDisplayName = "\(profile.payloadDisplayName) Copy"
        newProfile.payloadIdentifier = "\(profile.payloadIdentifier).copy"
        newProfile.payloadUUID = UUID().uuidString.uppercased()
        newProfile.createdDate = Date()
        newProfile.modifiedDate = Date()
        newProfile.filePath = nil
        
        // Generate new UUIDs for all payloads
        newProfile.payloadContent = profile.payloadContent.map { payload in
            // Create new payload with new UUID
            switch payload.payload {
            case var wifi as WiFiPayload:
                wifi.payloadUUID = UUID().uuidString.uppercased()
                wifi.payloadIdentifier = "\(newProfile.payloadIdentifier).wifi"
                return AnyPayload(wifi)
            case var vpn as VPNPayload:
                vpn.payloadUUID = UUID().uuidString.uppercased()
                vpn.payloadIdentifier = "\(newProfile.payloadIdentifier).vpn"
                return AnyPayload(vpn)
            default:
                return payload // Return original if we can't modify
            }
        }
        
        logger.info("Duplicated profile: \(profile.payloadDisplayName)")
        return newProfile
    }
    
    // MARK: - Profile Export
    
    /// Export profile as .mobileconfig file
    func exportProfile(_ profile: ConfigurationProfile, to url: URL, signed: Bool = false) throws {
        do {
            // Validate profile before export
            try validateProfile(profile)
            
            // Generate XML data
            let xmlData = try generateProfileXML(profile)
            
            let finalData: Data
            if signed {
                // TODO: Implement signing - for now just use unsigned
                finalData = xmlData
                logger.warning("Profile signing not yet implemented, exporting unsigned")
            } else {
                finalData = xmlData
            }
            
            try finalData.write(to: url)
            logger.info("Exported profile: \(profile.payloadDisplayName) to \(url.path)")
            
        } catch {
            logger.error("Failed to export profile: \(error)")
            throw ProfileServiceError.exportError(error.localizedDescription)
        }
    }
    
    /// Generate XML data for profile
    private func generateProfileXML(_ profile: ConfigurationProfile) throws -> Data {
        // Convert profile to dictionary for XML serialization
        var profileDict: [String: Any] = [
            "PayloadType": profile.payloadType,
            "PayloadVersion": profile.payloadVersion,
            "PayloadIdentifier": profile.payloadIdentifier,
            "PayloadUUID": profile.payloadUUID,
            "PayloadDisplayName": profile.payloadDisplayName,
            "PayloadDescription": profile.payloadDescription,
            "PayloadOrganization": profile.payloadOrganization,
            "PayloadScope": profile.payloadScope.rawValue,
            "PayloadRemovalDisallowed": profile.payloadRemovalDisallowed
        ]
        
        // Add metadata
        let dateFormatter = ISO8601DateFormatter()
        profileDict["PayloadCreationDate"] = dateFormatter.string(from: profile.createdDate)
        
        // Convert payloads to dictionaries
        profileDict["PayloadContent"] = profile.payloadContent.map { $0.dictionary }
        
        // Convert to XML using PropertyListSerialization
        do {
            return try PropertyListSerialization.data(
                fromPropertyList: profileDict,
                format: .xml,
                options: 0
            )
        } catch {
            throw ProfileServiceError.exportError("Failed to serialize profile to XML: \(error)")
        }
    }
    
    // MARK: - Profile Validation
    
    /// Validate a configuration profile
    func validateProfile(_ profile: ConfigurationProfile) throws {
        var errors: [String] = []
        
        // Basic validation
        if profile.payloadDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Profile name is required")
        }
        
        if profile.payloadIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Profile identifier is required")
        }
        
        if !isValidIdentifier(profile.payloadIdentifier) {
            errors.append("Profile identifier must be in reverse DNS format (e.g., com.company.profile)")
        }
        
        // Validate payloads
        for (index, payload) in profile.payloadContent.enumerated() {
            if let payloadErrors = validatePayload(payload, index: index) {
                errors.append(contentsOf: payloadErrors)
            }
        }
        
        if !errors.isEmpty {
            throw ProfileServiceError.validationError(errors)
        }
    }
    
    /// Validate an individual payload
    private func validatePayload(_ payload: AnyPayload, index: Int) -> [String]? {
        switch payload.payload {
        case let wifi as WiFiPayload:
            return wifi.validate()?.map { "Payload \(index + 1) (Wi-Fi): \($0)" }
        case let vpn as VPNPayload:
            return vpn.validate()?.map { "Payload \(index + 1) (VPN): \($0)" }
        default:
            return nil
        }
    }
    
    // MARK: - Profile Signing (Placeholder)
    
    /// Sign a configuration profile with a certificate
    func signProfile(_ profile: ConfigurationProfile, with certificate: SecIdentity) throws -> Data {
        // For now, just return the unsigned XML
        // TODO: Implement proper CMS signing
        logger.warning("Profile signing not yet implemented")
        return try generateProfileXML(profile)
    }
    
    /// Get available signing certificates from Keychain
    func getAvailableSigningCertificates() -> [SecIdentity] {
        // TODO: Implement certificate discovery
        logger.warning("Certificate discovery not yet implemented")
        return []
    }
    
    // MARK: - Utility Methods
    
    private func sanitizeFileName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidChars).joined(separator: "_")
    }
    
    private func isValidIdentifier(_ identifier: String) -> Bool {
        // Basic check for reverse DNS format
        let parts = identifier.split(separator: ".")
        return parts.count >= 2 && parts.allSatisfy { !$0.isEmpty }
    }
    
    // MARK: - Template Management
    
    /// Load available templates
    func loadTemplates() throws -> [ProfileTemplate] {
        // Return built-in templates for now
        return [
            ProfileTemplate.antivirusTemplate,
            ProfileTemplate.vpnTemplate
        ]
    }
    
    /// Apply a template to create a new profile
    func createProfileFromTemplate(_ template: ProfileTemplate, name: String? = nil) -> ConfigurationProfile {
        let profileName = name ?? template.name
        let identifier = "com.company.\(profileName.lowercased().replacingOccurrences(of: " ", with: ""))"
        
        var profile = ConfigurationProfile(name: profileName, identifier: identifier)
        profile.payloadDescription = template.description
        profile.payloadContent = template.payloads
        profile.tags = template.tags
        
        logger.info("Created profile from template: \(template.name)")
        return profile
    }
}

// MARK: - ConfigurationProfile Extension for File Path
extension ConfigurationProfile {
    var filePath: URL? {
        get { nil } // This would be stored separately in a real implementation
        set { } // Placeholder for file path storage
    }
}