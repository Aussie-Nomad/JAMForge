import Foundation

extension ConfigurationProfile {
    func exportToXML() throws -> Data {
        var profileDict: [String: Any] = [
            "PayloadType": payloadType,
            "PayloadVersion": payloadVersion,
            "PayloadIdentifier": payloadIdentifier,
            "PayloadUUID": payloadUUID,
            "PayloadDisplayName": payloadDisplayName,
            "PayloadDescription": payloadDescription,
            "PayloadOrganization": payloadOrganization,
            "PayloadScope": payloadScope.rawValue,
            "PayloadRemovalDisallowed": payloadRemovalDisallowed,
            "PayloadContent": payloadContent.map { $0.dictionary }
        ]
        
        // Add metadata
        profileDict["PayloadCreationDate"] = createdDate
        profileDict["PayloadModificationDate"] = modifiedDate
        
        // Convert to property list format
        return try PropertyListSerialization.data(
            fromPropertyList: profileDict,
            format: .xml,
            options: 0
        )
    }
}

extension AnyPayload {
    var dictionary: [String: Any] {
        switch payload {
        case let wifi as WiFiPayload:
            return wifi.dictionary
        case let vpn as VPNPayload:
            return vpn.dictionary
        case let cert as CertificatePayload:
            return cert.dictionary
        default:
            return [:]
        }
    }
}
