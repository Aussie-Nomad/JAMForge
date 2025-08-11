import Foundation

protocol Payload: Codable {
    var payloadType: String { get }
    var payloadVersion: Int { get }
    var payloadIdentifier: String { get }
    var payloadUUID: String { get }
    var payloadDisplayName: String { get }
    var payloadDescription: String? { get }
    var payloadOrganization: String? { get }
    
    func validate() -> [String]?
    var dictionary: [String: Any] { get }
}

struct WiFiPayload: Payload {
    // Common payload properties
    let payloadType = "com.apple.wifi.managed"
    let payloadVersion = 1
    let payloadIdentifier: String
    let payloadUUID = UUID().uuidString
    let payloadDisplayName: String
    var payloadDescription: String?
    var payloadOrganization: String?
    
    // WiFi specific properties
    var SSID_STR: String
    var hiddenNetwork: Bool
    var autoJoin: Bool
    var encryptionType: WiFiEncryption
    var password: String?
    var proxyType: ProxyType
    var proxyServer: String?
    var proxyPort: Int?
    var proxyUsername: String?
    var proxyPassword: String?
    
    enum WiFiEncryption: String, Codable {
        case none = "None"
        case wep = "WEP"
        case wpa = "WPA"
        case wpa2 = "WPA2"
        case wpa3 = "WPA3"
        case enterprise = "WPA2Enterprise"
    }
    
    enum ProxyType: String, Codable {
        case none = "None"
        case manual = "Manual"
        case auto = "Auto"
    }
    
    func validate() -> [String]? {
        var errors = [String]()
        
        if SSID_STR.isEmpty {
            errors.append("SSID is required")
        }
        
        if encryptionType != .none && password == nil {
            errors.append("Password is required for encrypted networks")
        }
        
        if proxyType == .manual {
            if proxyServer == nil {
                errors.append("Proxy server is required for manual proxy")
            }
            if proxyPort == nil {
                errors.append("Proxy port is required for manual proxy")
            }
        }
        
        return errors.isEmpty ? nil : errors
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "PayloadType": payloadType,
            "PayloadVersion": payloadVersion,
            "PayloadIdentifier": payloadIdentifier,
            "PayloadUUID": payloadUUID,
            "PayloadDisplayName": payloadDisplayName,
            "SSID_STR": SSID_STR,
            "HiddenNetwork": hiddenNetwork,
            "AutoJoin": autoJoin,
            "EncryptionType": encryptionType.rawValue
        ]
        
        if let desc = payloadDescription {
            dict["PayloadDescription"] = desc
        }
        
        if let org = payloadOrganization {
            dict["PayloadOrganization"] = org
        }
        
        if let pwd = password {
            dict["Password"] = pwd
        }
        
        // Add proxy settings if needed
        dict["ProxyType"] = proxyType.rawValue
        if proxyType == .manual {
            if let server = proxyServer {
                dict["ProxyServer"] = server
            }
            if let port = proxyPort {
                dict["ProxyPort"] = port
            }
            if let username = proxyUsername {
                dict["ProxyUsername"] = username
            }
            if let password = proxyPassword {
                dict["ProxyPassword"] = password
            }
        }
        
        return dict
    }
}

struct VPNPayload: Payload {
    // Common payload properties
    let payloadType = "com.apple.vpn.managed"
    let payloadVersion = 1
    let payloadIdentifier: String
    let payloadUUID = UUID().uuidString
    let payloadDisplayName: String
    var payloadDescription: String?
    var payloadOrganization: String?
    
    // VPN specific properties
    var vpnType: VPNType
    var server: String
    var account: String?
    var password: String?
    var certificate: Data?
    var enableOnDemand: Bool
    var disconnectOnSleep: Bool
    
    enum VPNType: String, Codable {
        case l2tp = "L2TP"
        case pptp = "PPTP"
        case ipsec = "IPSec"
        case ikeV2 = "IKEv2"
        case ciscoAnyConnect = "CiscoAnyConnect"
    }
    
    func validate() -> [String]? {
        var errors = [String]()
        
        if server.isEmpty {
            errors.append("Server is required")
        }
        
        switch vpnType {
        case .l2tp, .pptp:
            if account == nil || password == nil {
                errors.append("Account and password are required for \(vpnType.rawValue)")
            }
        case .ipsec, .ikeV2:
            if certificate == nil {
                errors.append("Certificate is required for \(vpnType.rawValue)")
            }
        case .ciscoAnyConnect:
            if account == nil {
                errors.append("Account is required for Cisco AnyConnect")
            }
        }
        
        return errors.isEmpty ? nil : errors
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "PayloadType": payloadType,
            "PayloadVersion": payloadVersion,
            "PayloadIdentifier": payloadIdentifier,
            "PayloadUUID": payloadUUID,
            "PayloadDisplayName": payloadDisplayName,
            "VPNType": vpnType.rawValue,
            "Server": server,
            "EnableOnDemand": enableOnDemand,
            "DisconnectOnSleep": disconnectOnSleep
        ]
        
        if let desc = payloadDescription {
            dict["PayloadDescription"] = desc
        }
        
        if let org = payloadOrganization {
            dict["PayloadOrganization"] = org
        }
        
        if let acc = account {
            dict["Account"] = acc
        }
        
        if let pwd = password {
            dict["Password"] = pwd
        }
        
        if let cert = certificate {
            dict["Certificate"] = cert
        }
        
        return dict
    }
}
