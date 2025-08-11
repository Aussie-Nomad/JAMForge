import Foundation
import Security
import CryptoKit

class SecurityManager {
    enum SecurityError: Error {
        case certificateNotFound
        case signingFailed
        case invalidCertificate
        case keychainError
    }
    
    // Sign profile with a certificate
    func signProfile(_ profileData: Data, with identity: SecIdentity) throws -> Data {
        // Create signing parameters
        let parameters = [
            kSecCMSCertificateChainMode: kSecCMSCertificateChainWithRoot,
            kSecCMSSignHashAlgorithm: kSecCMSHashingAlgorithmSHA256
        ] as CFDictionary
        
        // Sign the data
        var signedData: CFData?
        let status = SecCMSCreateSignedData(
            profileData as CFData,
            identity,
            parameters,
            &signedData
        )
        
        guard status == errSecSuccess, let data = signedData as Data? else {
            throw SecurityError.signingFailed
        }
        
        return data
    }
    
    // Get signing identity from keychain
    func getSigningIdentity(with name: String) throws -> SecIdentity {
        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecMatchSubjectContains as String: name,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let identity = item as! SecIdentity? else {
            throw SecurityError.certificateNotFound
        }
        
        return identity
    }
    
    // Validate profile signature
    func validateProfile(_ signedData: Data) throws -> Bool {
        var policy: SecPolicy?
        var trust: SecTrust?
        var signingCert: SecCertificate?
        
        // Create policy for basic X.509 validation
        policy = SecPolicyCreateBasicX509()
        
        // Get signer certificate
        let status = SecCMSCopyCertificatesFromMessage(signedData as CFData, &signingCert)
        guard status == errSecSuccess, let cert = signingCert else {
            throw SecurityError.invalidCertificate
        }
        
        // Create trust object
        var error = SecTrustCreateWithCertificates(cert, policy, &trust)
        guard error == errSecSuccess, let trustRef = trust else {
            throw SecurityError.invalidCertificate
        }
        
        // Evaluate trust
        var trustResult: SecTrustResultType = .invalid
        error = SecTrustEvaluate(trustRef, &trustResult)
        
        guard error == errSecSuccess else {
            throw SecurityError.invalidCertificate
        }
        
        return trustResult == .proceed || trustResult == .unspecified
    }
    
    // Store credentials securely in keychain
    func storeCredentials(_ credentials: JAMFCredentials) throws {
        let credentialsData = try JSONEncoder().encode(credentials)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.jamforge.credentials",
            kSecAttrAccount as String: credentials.serverURL,
            kSecValueData as String: credentialsData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete any existing credentials
        SecItemDelete(query as CFDictionary)
        
        // Add new credentials
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keychainError
        }
    }
    
    // Retrieve credentials from keychain
    func retrieveCredentials(for serverURL: String) throws -> JAMFCredentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.jamforge.credentials",
            kSecAttrAccount as String: serverURL,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let credentialsData = result as? Data,
              let credentials = try? JSONDecoder().decode(JAMFCredentials.self, from: credentialsData) else {
            throw SecurityError.keychainError
        }
        
        return credentials
    }
}

struct JAMFCredentials: Codable {
    let serverURL: String
    let username: String
    let password: String
    let apiClientID: String?
    let apiClientSecret: String?
}
