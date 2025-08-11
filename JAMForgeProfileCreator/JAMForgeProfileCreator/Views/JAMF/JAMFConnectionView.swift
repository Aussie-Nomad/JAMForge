import SwiftUI

struct JAMFConnectionView: View {
    let profile: ConfigurationProfile?
    @StateObject private var jamfService = JAMFAPIService()
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isConnecting = false
    @State private var showingDeployment = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("JAMF Pro Integration")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Connect to your JAMF Pro server to deploy profiles")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Connection Status
                ConnectionStatusView(status: jamfService.connectionStatus)
                
                // Connection Form
                if !jamfService.isConnected {
                    VStack(spacing: 16) {
                        TextField("JAMF Pro Server URL", text: $serverURL)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: connectToJAMF) {
                            HStack {
                                if isConnecting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "link")
                                }
                                Text(isConnecting ? "Connecting..." : "Connect")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isConnecting || serverURL.isEmpty || username.isEmpty || password.isEmpty)
                    }
                    .frame(maxWidth: 400)
                } else {
                    // Connected Actions
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connected to JAMF Pro")
                                .fontWeight(.semibold)
                        }
                        
                        if let profile = profile {
                            Button("Deploy Profile") {
                                showingDeployment = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        Button("View Existing Profiles") {
                            // Show profile list
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Disconnect") {
                            disconnect()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("JAMF Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            loadStoredCredentials()
        }
        .sheet(isPresented: $showingDeployment) {
            if let profile = profile {
                DeploymentView(profile: profile, jamfService: jamfService)
            }
        }
    }
    
    private func connectToJAMF() {
        isConnecting = true
        
        Task {
            do {
                try await jamfService.connect(to: serverURL, username: username, password: password)
                await MainActor.run {
                    isConnecting = false
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    jamfService.lastError = error as? JAMFError
                }
            }
        }
    }
    
    private func disconnect() {
        jamfService.isConnected = false
        jamfService.connectionStatus = .disconnected
    }
    
    private func loadStoredCredentials() {
        if let credentials = jamfService.loadStoredCredentials() {
            serverURL = credentials.server
            username = credentials.username
            password = credentials.password
        }
    }
}
