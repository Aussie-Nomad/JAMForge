//
//  ProfileBuilderView.swift
//  JAMForge Profile Builder
//
//  Created by JAMForge on $(date +%m/%d/%y).
//

import SwiftUI

struct ProfileBuilderView: View {
    @StateObject private var viewModel = ProfileBuilderViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main Content
            HStack(spacing: 0) {
                // Left Sidebar - Payload Library
                PayloadLibraryView(viewModel: viewModel)
                    .frame(width: 320)
                
                // Center - Profile Builder
                profileBuilderView
                
                // Right Sidebar - Configuration
                PayloadConfigurationView(viewModel: viewModel)
                    .frame(width: 320)
            }
            
            // Footer
            footerView
        }
        .background(Color.black)
    }
    
    private var headerView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange, Color.orange.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 80)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .frame(width: 400, height: 50)
                .overlay(
                    Text("JAMFORGE PROFILE BUILDER")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.yellow)
                        .tracking(2)
                )
        }
    }
    
    private var profileBuilderView: some View {
        VStack {
            // Profile Settings
            profileSettingsView
            
            // Active Payloads
            activePayloadsView
            
            // Action Buttons
            actionButtonsView
        }
        .padding()
        .background(Color.orange)
    }
    
    private var profileSettingsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFILE SETTINGS")
                .font(.headline)
                .fontWeight(.black)
                .foregroundColor(.black)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                TextField("Profile Name", text: $viewModel.profileSettings.name)
                    .textFieldStyle(JAMForgeTextFieldStyle())
                
                TextField("Organization", text: $viewModel.profileSettings.organization)
                    .textFieldStyle(JAMForgeTextFieldStyle())
                
                TextField("Identifier", text: $viewModel.profileSettings.identifier)
                    .textFieldStyle(JAMForgeTextFieldStyle())
                
                Picker("Scope", selection: $viewModel.profileSettings.scope) {
                    Text("System").tag("System")
                    Text("User").tag("User")
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .background(Color.yellow)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.orange)
        .cornerRadius(12)
    }
    
    private var activePayloadsView: some View {
        VStack(alignment: .leading) {
            Text("ACTIVE PAYLOADS")
                .font(.title2)
                .fontWeight(.black)
                .foregroundColor(.yellow)
            
            if viewModel.activePayloads.isEmpty {
                dropZoneView
            } else {
                payloadListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.black)
        .cornerRadius(16)
    }
    
    private var dropZoneView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 2, dash: [10]))
            .frame(height: 200)
            .overlay(
                VStack {
                    Text("DRAG PAYLOADS HERE")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.yellow)
                    
                    Text("Drop configuration payloads to build your profile")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.6))
                }
            )
            .onDrop(of: ["public.data"], isTargeted: nil) { providers in
                return viewModel.handleDrop(providers: providers)
            }
    }
    
    private var payloadListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.activePayloads) { payload in
                    PayloadRowView(payload: payload, viewModel: viewModel)
                }
            }
        }
        .onDrop(of: ["public.data"], isTargeted: nil) { providers in
            return viewModel.handleDrop(providers: providers)
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.exportProfile) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("EXPORT PROFILE")
                        .fontWeight(.black)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            
            Button(action: viewModel.saveProfile) {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("SAVE")
                }
                .padding()
                .background(Color.gray.opacity(0.7))
                .foregroundColor(.yellow)
                .cornerRadius(8)
            }
        }
    }
    
    private var footerView: some View {
        Text("JAMForge Profile Builder - Comprehensive configuration profile creation with \(viewModel.allPayloads.count) payload types")
            .font(.caption)
            .foregroundColor(.yellow.opacity(0.6))
            .padding()
            .background(Color.black)
    }
}

// MARK: - Custom Styles and Components

struct JAMForgeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(8)
            .background(Color.yellow)
            .foregroundColor(.black)
            .cornerRadius(8)
    }
}

struct PayloadRowView: View {
    let payload: Payload
    let viewModel: ProfileBuilderViewModel
    
    var body: some View {
        HStack {
            HStack {
                Text(payload.icon)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(payload.name)
                        .font(.headline)
                        .fontWeight(.black)
                    
                    Text(payload.description)
                        .font(.caption)
                        .opacity(0.7)
                    
                    HStack {
                        ForEach(payload.platforms, id: \.self) { platform in
                            HStack(spacing: 2) {
                                platformIcon(for: platform)
                                Text(platform)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            HStack {
                Button(action: { viewModel.selectPayload(payload) }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { viewModel.removePayload(payload) }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.yellow)
        .foregroundColor(.black)
        .cornerRadius(8)
        .onTapGesture {
            viewModel.selectPayload(payload)
        }
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
}

#Preview {
    ProfileBuilderView()
}