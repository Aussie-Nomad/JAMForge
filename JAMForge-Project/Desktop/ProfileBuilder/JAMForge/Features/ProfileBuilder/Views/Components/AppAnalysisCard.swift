import SwiftUI

struct AppAnalysisCard: View {
    let result: AppAnalysisResult
    @ObservedObject var profile: ConfigurationProfile
    @State private var showingPermissionDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App Header
            HStack {
                Image(systemName: "app.dashed")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading) {
                    Text(result.displayName)
                        .font(.headline)
                    Text(result.bundleIdentifier)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Badge(text: result.appCategory.rawValue, color: .blue)
            }
            
            // Required Permissions
            if !result.requiredPermissions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Required Permissions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Button(action: { showingPermissionDetails = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(result.requiredPermissions, id: \.rawValue) { permission in
                            PermissionChip(permission: permission)
                        }
                    }
                }
            }
            
            // Suggested Payloads
            if !result.suggestedPayloads.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Configuration")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(result.suggestedPayloads, id: \.rawValue) { payloadType in
                        PayloadSuggestionRow(payloadType: payloadType)
                    }
                }
            }
            
            // Action Buttons
            HStack {
                Button("Apply Suggestions") {
                    applySuggestions()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Customize") {
                    // Open detailed configuration
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Dismiss") {
                    // Clear analysis result
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .sheet(isPresented: $showingPermissionDetails) {
            PermissionDetailsSheet(permissions: result.requiredPermissions)
        }
    }
    
    private func applySuggestions() {
        // Apply suggested payloads to profile
        for payloadType in result.suggestedPayloads {
            switch payloadType {
            case .privacyPreferences:
                // TODO: Implement PPPCPayload
                break
            case .systemPolicy:
                // TODO: Implement SystemPolicyPayload
                break
            default:
                break
            }
        }
    }
}
