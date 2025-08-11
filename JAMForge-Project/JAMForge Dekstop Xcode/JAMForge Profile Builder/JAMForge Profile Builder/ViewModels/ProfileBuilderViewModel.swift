//
//  ProfileBuilderViewModel.swift
//  JAMForge Profile Builder
//
//  Created by JAMForge on $(date +%m/%d/%y).
//

import Foundation
import SwiftUI

class ProfileBuilderViewModel: ObservableObject {
   @Published var activePayloads: [Payload] = []
   @Published var selectedPayload: Payload?
   @Published var profileSettings = ProfileSettings()
   @Published var draggedPayload: Payload?
   
   private var payloadSettings: [String: [String: Any]] = [:]
   
   let allPayloads: [Payload] = [
       Payload(id: "wifi", name: "Wi-Fi", description: "Configure Wi-Fi network settings", platforms: ["iOS", "macOS", "tvOS"], icon: "📶", category: "Network"),
       Payload(id: "vpn", name: "VPN", description: "Virtual Private Network configuration", platforms: ["iOS", "macOS", "tvOS"], icon: "🔒", category: "Network"),
       Payload(id: "passcode", name: "Passcode", description: "Device passcode policy", platforms: ["iOS", "macOS", "tvOS"], icon: "🔐", category: "Security"),
       Payload(id: "restrictions", name: "Restrictions", description: "Device and app restrictions", platforms: ["iOS", "macOS", "tvOS"], icon: "🚫", category: "Security"),
       Payload(id: "firewall", name: "Firewall", description: "System firewall configuration", platforms: ["macOS"], icon: "🛡️", category: "Security"),
       Payload(id: "filevault2", name: "FileVault 2", description: "Disk encryption settings", platforms: ["macOS"], icon: "🔒", category: "Security"),
       Payload(id: "pppc", name: "Privacy Preferences Policy Control", description: "Privacy and security permissions", platforms: ["macOS"], icon: "🔐", category: "Security"),
       Payload(id: "certificate-root", name: "Certificate Root", description: "Root certificate installation", platforms: ["iOS", "macOS", "tvOS"], icon: "📋", category: "Certificates"),
       Payload(id: "scep", name: "SCEP", description: "Simple Certificate Enrollment Protocol", platforms: ["iOS", "macOS", "tvOS"], icon: "🔄", category: "Certificates"),
       Payload(id: "dock", name: "Dock", description: "macOS Dock configuration", platforms: ["macOS"], icon: "📱", category: "User Experience"),
       Payload(id: "finder", name: "Finder", description: "Finder app settings", platforms: ["macOS"], icon: "📁", category: "User Experience"),
       Payload(id: "desktop", name: "Desktop Picture", description: "Set desktop wallpaper", platforms: ["macOS"], icon: "🖼️", category: "User Experience"),
       Payload(id: "notifications", name: "Notifications", description: "Notification settings per app", platforms: ["iOS", "macOS"], icon: "🔔", category: "User Experience"),
       Payload(id: "active-directory", name: "Active Directory", description: "Active Directory binding", platforms: ["macOS"], icon: "🏢", category: "Accounts"),
       Payload(id: "mail", name: "Mail", description: "Email account configuration", platforms: ["iOS", "macOS"], icon: "📧", category: "Accounts"),
       Payload(id: "calendar", name: "Calendar", description: "CalDAV calendar account", platforms: ["iOS", "macOS"], icon: "📅", category: "Accounts"),
       Payload(id: "google-chrome", name: "Google Chrome", description: "Chrome browser settings", platforms: ["macOS"], icon: "🌐", category: "Applications"),
       Payload(id: "zoom", name: "Zoom", description: "Zoom client settings", platforms: ["macOS"], icon: "📹", category: "Applications"),
       Payload(id: "slack", name: "Slack", description: "Slack messaging app settings", platforms: ["macOS"], icon: "💬", category: "Applications")
   ]
   
   let categories = ["All", "Network", "Security", "Certificates", "User Experience", "Accounts", "Applications"]
   
   let templates = [
       ProfileTemplate(name: "Security Baseline", description: "Essential security settings for enterprise deployment", payloadIds: ["passcode", "restrictions", "firewall", "filevault2", "pppc"]),
       ProfileTemplate(name: "Network Configuration", description: "Complete network setup including Wi-Fi, VPN, and certificates", payloadIds: ["wifi", "vpn", "certificate-root"]),
       ProfileTemplate(name: "User Experience", description: "Standardized user interface and experience settings", payloadIds: ["dock", "desktop", "finder", "notifications"]),
       ProfileTemplate(name: "Antivirus Setup", description: "Security software deployment with required permissions", payloadIds: ["pppc", "restrictions"])
   ]
   
   func handleDrop(providers: [NSItemProvider]) -> Bool {
       guard let draggedPayload = draggedPayload else { return false }
       
       if !activePayloads.contains(where: { $0.id == draggedPayload.id }) {
           let newPayload = Payload(
               id: draggedPayload.id,
               name: draggedPayload.name,
               description: draggedPayload.description,
               platforms: draggedPayload.platforms,
               icon: draggedPayload.icon,
               category: draggedPayload.category
           )
           activePayloads.append(newPayload)
       }
       
       self.draggedPayload = nil
       return true
   }
   
   func removePayload(_ payload: Payload) {
       activePayloads.removeAll { $0.id == payload.id }
       if selectedPayload?.id == payload.id {
           selectedPayload = nil
       }
       payloadSettings.removeValue(forKey: payload.id)
   }
   
   func selectPayload(_ payload: Payload) {
       selectedPayload = payload
   }
   
   func applyTemplate(_ template: ProfileTemplate) {
       activePayloads.removeAll()
       
       for payloadId in template.payloadIds {
           if let payload = allPayloads.first(where: { $0.id == payloadId }) {
               let newPayload = Payload(
                   id: payload.id,
                   name: payload.name,
                   description: payload.description,
                   platforms: payload.platforms,
                   icon: payload.icon,
                   category: payload.category
               )
               activePayloads.append(newPayload)
           }
       }
   }
   
   func setPayloadSetting(_ payloadId: String, key: String, value: Any) {
       if payloadSettings[payloadId] == nil {
           payloadSettings[payloadId] = [:]
       }
       payloadSettings[payloadId]?[key] = value
   }
   
   func getPayloadSetting(_ payloadId: String, key: String) -> Any? {
       return payloadSettings[payloadId]?[key]
   }
   
   func exportProfile() {
       let profile: [String: Any] = [
           "PayloadContent": activePayloads.map { payload in
               var content: [String: Any] = [
                   "PayloadType": "com.apple.\(payload.id)",
                   "PayloadIdentifier": "\(profileSettings.identifier).\(payload.id)",
                   "PayloadUUID": payload.uuid,
                   "PayloadDisplayName": payload.name,
                   "PayloadDescription": payload.description,
                   "PayloadVersion": 1,
                   "PayloadEnabled": payload.enabled
               ]
               
               if let settings = payloadSettings[payload.id] {
                   content.merge(settings) { _, new in new }
               }
               
               return content
           },
           "PayloadDisplayName": profileSettings.name,
           "PayloadDescription": profileSettings.description,
           "PayloadIdentifier": profileSettings.identifier,
           "PayloadOrganization": profileSettings.organization,
           "PayloadScope": profileSettings.scope,
           "PayloadType": "Configuration",
           "PayloadUUID": UUID().uuidString,
           "PayloadVersion": 1
       ]
       
       // Export to file
       let panel = NSSavePanel()
       panel.nameFieldStringValue = "\(profileSettings.name.replacingOccurrences(of: " ", with: "-")).mobileconfig"
       panel.allowedContentTypes = [.json]
       
       panel.begin { result in
           if result == .OK, let url = panel.url {
               do {
                   let data = try JSONSerialization.data(withJSONObject: profile, options: .prettyPrinted)
                   try data.write(to: url)
               } catch {
                   print("Error saving profile: \(error)")
               }
           }
       }
   }
   
   func saveProfile() {
       // Implement save functionality
       print("Save profile functionality")
   }
}
