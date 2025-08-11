import SwiftUI

struct DeploymentView: View {
    let profile: ConfigurationProfile
    @ObservedObject var jamfService: JAMFAPIService
    @State private var selectedScope: ProfileScope = .user
    @State private var scopeTargets = ScopeTargets()
    @State private var isDeploying = false
    @State private var deploymentResult: DeploymentResult?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Profile Summary
                    ProfileSummaryCard(profile: profile)
                    
                    // Scope Configuration
                    ScopeConfigurationView(
                        selectedScope: $selectedScope,
                        scopeTargets: $scopeTargets
                    )
                    
                    // Deployment Options
                    DeploymentOptionsView()
                    
                    // Deploy Button
                    Button(action: deployProfile) {
                        HStack {
                            if isDeploying {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isDeploying ? "Deploying..." : "Deploy to JAMF Pro")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isDeploying)
                    
                    // Deployment Result
                    if let result = deploymentResult {
                        DeploymentResultView(result: result)
                    }
                }
                .padding()
            }
            .navigationTitle("Deploy Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    private func deployProfile() {
        isDeploying = true
        deploymentResult = nil
        
        Task {
            do {
                let response = try await jamfService.uploadProfile(profile, scope: selectedScope)
                
                // Assign scope if not all computers
                if !scopeTargets.allComputers {
                    try await jamfService.assignScope(
                        profileId: response.id,
                        scope: selectedScope,
                        targets: scopeTargets
                    )
                }
                
                await MainActor.run {
                    isDeploying = false
                    deploymentResult = .success(response)
                }
            } catch {
                await MainActor.run {
                    isDeploying = false
                    deploymentResult = .failure(error)
                }
            }
        }
    }
}

struct ProfileSummaryCard: View {
    let profile: ConfigurationProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile Summary")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Name:")
                        .fontWeight(.medium)
                    Text(profile.payloadDisplayName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Identifier:")
                        .fontWeight(.medium)
                    Text(profile.payloadIdentifier)
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Payloads:")
                        .fontWeight(.medium)
                    Text("\(profile.payloadContent.count)")
                        .foregroundColor(.secondary)
                }
                
                if !profile.payloadDescription.isEmpty {
                    HStack(alignment: .top) {
                        Text("Description:")
                            .fontWeight(.medium)
                        Text(profile.payloadDescription)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

enum DeploymentResult {
    case success(JAMFProfileResponse)
    case failure(Error)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

struct DeploymentResultView: View {
    let result: DeploymentResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch result {
            case .success(let response):
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Deployment Successful")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("Profile ID: \(response.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
            case .failure(let error):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Deployment Failed")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            result.isSuccess ?
            Color.green.opacity(0.1) :
            Color.red.opacity(0.1)
        )
        .cornerRadius(8)
    }
}
