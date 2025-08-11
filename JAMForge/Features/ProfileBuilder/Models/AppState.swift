import Foundation

class AppState: ObservableObject {
    @Published var currentTheme: Theme = .dark
    @Published var jamfConfiguration: JAMFConfiguration?
    @Published var securitySettings: SecuritySettings = SecuritySettings()
    
    enum Theme: String, CaseIterable {
        case dark = "Dark"
        case auto = "Auto"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .dark: return .dark
            case .auto: return nil
            }
        }
    }
}

struct JAMFConfiguration: Codable {
    var serverURL: String
    var username: String
    var apiToken: String?
}

struct SecuritySettings: Codable {
    var requireProfileSigning: Bool = true
    var validateCertificates: Bool = true
    var enforcePasswordPolicy: Bool = true
    var encryptedStorage: Bool = true
}
