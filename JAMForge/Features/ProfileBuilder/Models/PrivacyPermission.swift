import Foundation
import SwiftUI

enum PrivacyPermission: String, CaseIterable {
    case fullDiskAccess = "Full Disk Access"
    case fileSystemAccess = "File System Access"
    case cameraAccess = "Camera Access"
    case microphoneAccess = "Microphone Access"
    case contactsAccess = "Contacts Access"
    case calendarAccess = "Calendar Access"
    case remindersAccess = "Reminders Access"
    case photosAccess = "Photos Access"
    case locationAccess = "Location Services"
    case networkAccess = "Network Access"
    case systemPolicyControl = "System Policy Control"
    case privacyPreferences = "Privacy Preferences Policy Control"
    
    var description: String {
        switch self {
        case .fullDiskAccess:
            return "Grants the application complete access to all files on the system, including system files, other users' data, and encrypted files. This is the highest level of file system access."
        case .fileSystemAccess:
            return "Allows the application to access files outside of its designated container, including user documents and system folders."
        case .cameraAccess:
            return "Permits the application to use the device's camera to capture photos and videos."
        case .microphoneAccess:
            return "Allows the application to record audio using the device's microphone."
        case .contactsAccess:
            return "Grants access to the user's contact information stored in the Contacts app."
        case .calendarAccess:
            return "Permits reading and writing calendar events and scheduling information."
        case .remindersAccess:
            return "Allows access to the user's reminders and task lists."
        case .photosAccess:
            return "Grants access to the user's photo library, including the ability to read and write photos."
        case .locationAccess:
            return "Permits the application to access the device's location information."
        case .networkAccess:
            return "Allows the application to make network connections and access internet resources."
        case .systemPolicyControl:
            return "Grants the ability to control system-level security policies and override security restrictions."
        case .privacyPreferences:
            return "Allows the application to control privacy preferences and permissions for other applications."
        }
    }
    
    var icon: String {
        switch self {
        case .fullDiskAccess: return "internaldrive"
        case .fileSystemAccess: return "folder"
        case .cameraAccess: return "camera"
        case .microphoneAccess: return "mic"
        case .contactsAccess: return "person.crop.circle"
        case .calendarAccess: return "calendar"
        case .remindersAccess: return "checklist"
        case .photosAccess: return "photo.on.rectangle"
        case .locationAccess: return "location"
        case .networkAccess: return "network"
        case .systemPolicyControl: return "shield"
        case .privacyPreferences: return "hand.raised"
        }
    }
    
    var riskLevel: RiskLevel {
        switch self {
        case .fullDiskAccess, .systemPolicyControl, .privacyPreferences:
            return .high
        case .fileSystemAccess, .cameraAccess, .microphoneAccess, .locationAccess:
            return .medium
        case .contactsAccess, .calendarAccess, .remindersAccess, .photosAccess, .networkAccess:
            return .low
        }
    }
}

enum RiskLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
