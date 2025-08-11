//
//  PayloadConfigurationView.swift
//  JAMForge Profile Builder
//
//  Created by JAMForge on $(date +%m/%d/%y).
//

import SwiftUI

struct PayloadConfigurationView: View {
   @ObservedObject var viewModel: ProfileBuilderViewModel
   
   var body: some View {
       VStack {
           headerView
           
           if let selectedPayload = viewModel.selectedPayload {
               configurationContentView(for: selectedPayload)
           } else {
               emptyStateView
           }
       }
       .background(Color.orange)
       .padding()
   }
   
   private var headerView: some View {
       RoundedRectangle(cornerRadius: 16)
           .fill(Color.black)
           .frame(height: 40)
           .overlay(
               Text("PAYLOAD SETTINGS")
                   .font(.headline)
                   .fontWeight(.black)
                   .foregroundColor(.yellow)
           )
   }
   
   private func configurationContentView(for payload: Payload) -> some View {
       ScrollView {
           VStack(alignment: .leading, spacing: 16) {
               // Payload Info
               payloadInfoView(for: payload)
               
               // Basic Settings
               basicSettingsView(for: payload)
               
               // Specific Configuration
               specificConfigurationView(for: payload)
           }
           .padding()
       }
       .background(Color.black)
       .cornerRadius(12)
   }
   
   private func payloadInfoView(for payload: Payload) -> some View {
       VStack(alignment: .leading, spacing: 8) {
           HStack {
               Text(payload.icon)
                   .font(.title)
               
               VStack(alignment: .leading) {
                   Text(payload.name)
                       .font(.headline)
                       .fontWeight(.black)
                       .foregroundColor(.yellow)
                   
                   Text(payload.description)
                       .font(.caption)
                       .foregroundColor(.yellow.opacity(0.7))
               }
               
               Spacer()
           }
       }
   }
   
   private func basicSettingsView(for payload: Payload) -> some View {
       VStack(alignment: .leading, spacing: 12) {
           VStack(alignment: .leading, spacing: 4) {
               Text("PAYLOAD IDENTIFIER")
                   .font(.caption)
                   .fontWeight(.black)
                   .foregroundColor(.yellow)
               
               Text("\(viewModel.profileSettings.identifier).\(payload.id)")
                   .padding(8)
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .background(Color.yellow)
                   .foregroundColor(.black)
                   .cornerRadius(6)
           }
           
           VStack(alignment: .leading, spacing: 4) {
               Text("PLATFORMS")
                   .font(.caption)
                   .fontWeight(.black)
                   .foregroundColor(.yellow)
               
               HStack {
                   ForEach(payload.platforms, id: \.self) { platform in
                       platformBadge(platform)
                   }
               }
           }
       }
   }
   
   private func platformBadge(_ platform: String) -> some View {
       HStack(spacing: 4) {
           platformIcon(for: platform)
           Text(platform)
               .font(.caption2)
       }
       .padding(.horizontal, 8)
       .padding(.vertical, 4)
       .background(Color.yellow)
       .foregroundColor(.black)
       .cornerRadius(4)
   }
   
   @ViewBuilder
   private func platformIcon(for platform: String) -> some View {
       switch platform {
       case "iOS":
           Image(systemName: "iphone")
               .foregroundColor(.blue)
       case "macOS":
           Image(systemName: "laptopcomputer")
               .foregroundColor(.gray)
       case "tvOS":
           Image(systemName: "appletv")
               .foregroundColor(.purple)
       default:
           Image(systemName: "questionmark")
       }
   }
   
   @ViewBuilder
   private func specificConfigurationView(for payload: Payload) -> some View {
       VStack(alignment: .leading, spacing: 12) {
           Rectangle()
               .fill(Color.yellow.opacity(0.3))
               .frame(height: 1)
           
           Text("CONFIGURATION OPTIONS")
               .font(.caption)
               .fontWeight(.black)
               .foregroundColor(.yellow)
           
           switch payload.id {
           case "wifi":
               wifiConfigurationView(for: payload)
           case "restrictions":
               restrictionsConfigurationView(for: payload)
           case "pppc":
               pppcConfigurationView(for: payload)
           default:
               defaultConfigurationView()
           }
       }
   }
   
   private func wifiConfigurationView(for payload: Payload) -> some View {
       VStack(alignment: .leading, spacing: 12) {
           ConfigurationField(
               label: "SSID",
               placeholder: "Network name",
               text: Binding(
                   get: { viewModel.getPayloadSetting(payload.id, key: "SSID") as? String ?? "" },
                   set: { viewModel.setPayloadSetting(payload.id, key: "SSID", value: $0) }
               )
           )
           
           VStack(alignment: .leading, spacing: 4) {
               Text("SECURITY TYPE")
                   .font(.caption2)
                   .foregroundColor(.yellow)
               
               Picker("Security", selection: Binding(
                   get: { viewModel.getPayloadSetting(payload.id, key: "SecurityType") as? String ?? "WPA2 Personal" },
                   set: { viewModel.setPayloadSetting(payload.id, key: "SecurityType", value: $0) }
               )) {
                   Text("WPA2 Personal").tag("WPA2 Personal")
                   Text("WPA3 Personal").tag("WPA3 Personal")
                   Text("WPA2 Enterprise").tag("WPA2 Enterprise")
               }
               .pickerStyle(MenuPickerStyle())
               .padding(8)
               .background(Color.yellow)
               .cornerRadius(6)
           }
           
           ConfigurationField(
               label: "PASSWORD",
               placeholder: "Network password",
               text: Binding(
                   get: { viewModel.getPayloadSetting(payload.id, key: "Password") as? String ?? "" },
                   set: { viewModel.setPayloadSetting(payload.id, key: "Password", value: $0) }
               ),
               isSecure: true
           )
       }
   }
   
   private func restrictionsConfigurationView(for payload: Payload) -> some View {
       VStack(alignment: .leading, spacing: 8) {
           ForEach(["Allow App Installation", "Allow Camera", "Allow Screen Recording", "Allow Safari"], id: \.self) { option in
               Toggle(option, isOn: Binding(
                   get: { viewModel.getPayloadSetting(payload.id, key: option) as? Bool ?? false },
                   set: { viewModel.setPayloadSetting(payload.id, key: option, value: $0) }
               ))
               .font(.caption2)
               .foregroundColor(.yellow)
           }
       }
   }
   
   private func pppcConfigurationView(for payload: Payload) -> some View {
       VStack(alignment: .leading, spacing: 12) {
           ConfigurationField(
               label: "BUNDLE IDENTIFIER",
               placeholder: "com.example.app",
               text: Binding(
                   get: { viewModel.getPayloadSetting(payload.id, key: "BundleIdentifier") as? String ?? "" },
                   set: { viewModel.setPayloadSetting(payload.id, key: "BundleIdentifier", value: $0) }
               )
           )
           
           VStack(alignment: .leading, spacing: 4) {
               Text("PRIVACY CATEGORY")
                   .font(.caption2)
                   .foregroundColor(.yellow)
               
               Picker("Category", selection: Binding(
                   get: { viewModel.getPayloadSetting(payload.id, key: "PrivacyCategory") as? String ?? "Camera" },
                   set: { viewModel.setPayloadSetting(payload.id, key: "PrivacyCategory", value: $0) }
               )) {
                   Text("Camera").tag("Camera")
                   Text("Microphone").tag("Microphone")
                   Text("Location Services").tag("Location Services")
                   Text("Photos").tag("Photos")
                   Text("Full Disk Access").tag("Full Disk Access")
               }
               .pickerStyle(MenuPickerStyle())
               .padding(8)
               .background(Color.yellow)
               .cornerRadius(6)
           }
           
           VStack(alignment: .leading, spacing: 4) {
               Text("ACCESS")
                   .font(.caption2)
                   .foregroundColor(.yellow)
               
               Picker("Access", selection: Binding(
                   get: { viewModel.getPayloadSetting(payload.id, key: "Access") as? String ?? "Allow" },
                   set: { viewModel.setPayloadSetting(payload.id, key: "Access", value: $0) }
               )) {
                   Text("Allow").tag("Allow")
                   Text("Deny").tag("Deny")
               }
               .pickerStyle(MenuPickerStyle())
               .padding(8)
               .background(Color.yellow)
               .cornerRadius(6)
           }
       }
   }
   
   private func defaultConfigurationView() -> some View {
       Text("Advanced configuration options will appear here based on the selected payload type.")
           .font(.caption)
           .foregroundColor(.yellow.opacity(0.6))
           .italic()
           .frame(maxWidth: .infinity)
           .padding()
   }
   
   private var emptyStateView: some View {
       VStack {
           Image(systemName: "gearshape")
               .font(.system(size: 48))
               .foregroundColor(.yellow.opacity(0.4))
           
           Text("Select a payload from the center panel to configure its settings")
               .font(.caption)
               .foregroundColor(.yellow.opacity(0.6))
               .multilineTextAlignment(.center)
       }
       .frame(maxWidth: .infinity, maxHeight: .infinity)
       .background(Color.black)
       .cornerRadius(12)
   }
}

struct ConfigurationField: View {
   let label: String
   let placeholder: String
   @Binding var text: String
   var isSecure: Bool = false
   
   var body: some View {
       VStack(alignment: .leading, spacing: 4) {
           Text(label)
               .font(.caption2)
               .foregroundColor(.yellow)
           
           if isSecure {
               SecureField(placeholder, text: $text)
                   .textFieldStyle(JAMForgeTextFieldStyle())
           } else {
               TextField(placeholder, text: $text)
                   .textFieldStyle(JAMForgeTextFieldStyle())
           }
       }
   }
}
