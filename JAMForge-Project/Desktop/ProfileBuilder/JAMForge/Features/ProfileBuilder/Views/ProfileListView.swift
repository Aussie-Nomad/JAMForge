// JAMForge/Features/ProfileBuilder/Views/ProfileListView.swift
import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    
    var filteredProfiles: [ConfigurationProfile] {
        if searchText.isEmpty {
            return appState.profiles
        } else {
            return appState.profiles.filter { profile in
                profile.payloadDisplayName.localizedCaseInsensitiveContains(searchText) ||
                profile.payloadIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List(filteredProfiles, selection: $appState.selectedProfile) { profile in
            ProfileRowView(profile: profile)
                .tag(profile)
        }
        .searchable(text: $searchText, prompt: "Search profiles...")
        .overlay {
            if appState.profiles.isEmpty {
                ProfileEmptyStateView()
            }
        }
    }
}

struct ProfileRowView: View {
    let profile: ConfigurationProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.payloadDisplayName)
                .font(.headline)
            
            Text(profile.payloadIdentifier)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(profile.payloadContent.count) payloads")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(profile.modifiedDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// JAMForge/Features/ProfileBuilder/Views/ProfileHeaderView.swift
struct ProfileHeaderView: View {
    @ObservedObject var profile: ConfigurationProfile
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                if isEditing {
                    TextField("Profile Name", text: $profile.payloadDisplayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(profile.payloadDisplayName)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text(profile.payloadIdentifier)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .font(.system(.body, design: .monospaced))
                
                if !profile.payloadDescription.isEmpty {
                    Text(profile.payloadDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("\(profile.payloadContent.count)", systemImage: "doc.text")
                    Label(profile.payloadScope.rawValue, systemImage: "person.circle")
                    Label("v\(profile.version)", systemImage: "number.circle")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
                .buttonStyle(.bordered)
                
                Menu("Actions") {
                    Button("Duplicate") {
                        // TODO: Duplicate profile
                    }
                    
                    Button("Export") {
                        // TODO: Export profile
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        // TODO: Delete profile
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

// JAMForge/Features/ProfileBuilder/Views/PayloadListSection.swift
struct PayloadListSection: View {
    @ObservedObject var profile: ConfigurationProfile
    @Binding var selectedPayload: AnyPayload?
    @State private var showingPayloadPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payloads")
                    .font(.headline)
                
                Spacer()
                
                Button("Add Payload") {
                    showingPayloadPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            if profile.payloadContent.isEmpty {
                PayloadEmptyStateView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(profile.payloadContent) { payload in
                        PayloadRowView(payload: payload)
                            .onTapGesture {
                                selectedPayload = payload
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPayloadPicker) {
            PayloadPickerView(profile: profile)
        }
    }
}

struct PayloadRowView: View {
    let payload: AnyPayload
    
    var body: some View {
        HStack {
            Image(systemName: payloadIcon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payloadDisplayName)
                    .font(.headline)
                
                Text(payloadType)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .font(.system(.caption, design: .monospaced))
            }
            
            Spacer()
            
            Button("Edit") {
                // TODO: Edit payload
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var payloadDisplayName: String {
        switch payload.payload {
        case let wifi as WiFiPayload:
            return wifi.payloadDisplayName
        case let vpn as VPNPayload:
            return vpn.payloadDisplayName
        default:
            return "Unknown Payload"
        }
    }
    
    private var payloadType: String {
        switch payload.payload {
        case let wifi as WiFiPayload:
            return wifi.payloadType
        case let vpn as VPNPayload:
            return vpn.payloadType
        default:
            return "unknown"
        }
    }
    
    private var payloadIcon: String {
        switch payload.payload {
        case is WiFiPayload:
            return "wifi"
        case is VPNPayload:
            return "globe"
        default:
            return "doc.text"
        }
    }
}

struct PayloadEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Payloads")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add payloads to configure device settings")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// JAMForge/Features/ProfileBuilder/Views/PayloadPickerView.swift
struct PayloadPickerView: View {
    @ObservedObject var profile: ConfigurationProfile
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: PayloadCategory = .network
    
    var body: some View {
        NavigationView {
            VStack {
                // Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(PayloadCategory.allCases, id: \.rawValue) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Payload List
                List {
                    ForEach(availablePayloads, id: \.rawValue) { payloadType in
                        PayloadTypeRow(payloadType: payloadType) {
                            addPayload(type: payloadType)
                        }
                    }
                }
            }
            .navigationTitle("Add Payload")
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
    }
    
    private var availablePayloads: [PayloadType] {
        switch selectedCategory {
        case .network:
            return [.wifi, .vpn]
        case .security:
            return [.certificate, .systemPolicy]
        case .restrictions:
            return [.restrictions]
        case .accounts:
            return [.email, .exchange]
        case .device:
            return []
        case .privacy:
            return [.privacyPreferences]
        }
    }
    
    private func addPayload(type: PayloadType) {
        switch type {
        case .wifi:
            let wifiPayload = WiFiPayload(
                payloadIdentifier: "\(profile.payloadIdentifier).wifi",
                payloadDisplayName: "Wi-Fi Settings",
                SSID_STR: "Network Name",
                hiddenNetwork: false,
                autoJoin: true,
                encryptionType: .wpa2,
                proxyType: .none
            )
            profile.payloadContent.append(AnyPayload(wifiPayload))
        case .vpn:
            let vpnPayload = VPNPayload(
                payloadIdentifier: "\(profile.payloadIdentifier).vpn",
                payloadDisplayName: "VPN Settings",
                vpnType: .ikeV2,
                server: "vpn.example.com",
                enableOnDemand: false,
                disconnectOnSleep: false
            )
            profile.payloadContent.append(AnyPayload(vpnPayload))
        default:
            // TODO: Implement other payload types
            break
        }
        
        dismiss()
    }
}

struct PayloadTypeRow: View {
    let payloadType: PayloadType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: payloadIcon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading) {
                    Text(payloadDisplayName)
                        .font(.headline)
                    Text(payloadDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var payloadDisplayName: String {
        switch payloadType {
        case .wifi: return "Wi-Fi"
        case .vpn: return "VPN"
        case .certificate: return "Certificate"
        case .restrictions: return "Restrictions"
        case .privacyPreferences: return "Privacy Preferences"
        case .systemPolicy: return "System Policy"
        case .email: return "Email"
        case .exchange: return "Exchange"
        }
    }
    
    private var payloadDescription: String {
        switch payloadType {
        case .wifi: return "Configure Wi-Fi network settings"
        case .vpn: return "Configure VPN connection settings"
        case .certificate: return "Install certificates"
        case .restrictions: return "Restrict device capabilities"
        case .privacyPreferences: return "Configure app privacy permissions"
        case .systemPolicy: return "Configure system security policies"
        case .email: return "Configure email account settings"
        case .exchange: return "Configure Exchange account settings"
        }
    }
    
    private var payloadIcon: String {
        switch payloadType {
        case .wifi: return "wifi"
        case .vpn: return "globe"
        case .certificate: return "key"
        case .restrictions: return "hand.raised"
        case .privacyPreferences: return "hand.raised.circle"
        case .systemPolicy: return "shield"
        case .email: return "mail"
        case .exchange: return "building.2"
        }
    }
}

// JAMForge/App/SettingsView.swift
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appState.isDarkMode) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("JAMF Pro") {
                    HStack {
                        Text("Connection Status")
                        Spacer()
                        Text(appState.isJAMFConnected ? "Connected" : "Disconnected")
                            .foregroundColor(appState.isJAMFConnected ? .green : .red)
                    }
                    
                    Button("Configure JAMF Connection") {
                        appState.showJAMFConnection = true
                        dismiss()
                    }
                }
                
                Section("Security") {
                    Toggle("Require Profile Signing", isOn: .constant(true))
                    Toggle("Validate Certificates", isOn: .constant(true))
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// JAMForge/Features/ProfileBuilder/Views/ConnectionStatusView.swift
struct ConnectionStatusView: View {
    let status: ConnectionStatus
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            Text(status.description)
                .font(.subheadline)
                .foregroundColor(statusColor)
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch status {
        case .disconnected: return "circle"
        case .connecting: return "circle.dotted"
        case .connected: return "circle.fill"
        case .failed: return "exclamationmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .disconnected: return .secondary
        case .connecting: return .orange
        case .connected: return .green
        case .failed: return .red
        }
    }
}

// JAMForge/Features/ProfileBuilder/Views/EmptyStateViews.swift
struct ProfileEmptyStateView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Profiles")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Create your first configuration profile to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button("Create New Profile") {
                    let newProfile = ConfigurationProfile(
                        name: "New Profile",
                        identifier: "com.company.newprofile"
                    )
                    appState.profiles.append(newProfile)
                    appState.selectedProfile = newProfile
                }
                .buttonStyle(.borderedProminent)
                
                Button("Browse Templates") {
                    appState.showTemplateLibrary = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

// JAMForge/Features/ProfileBuilder/Views/PayloadEditorView.swift
struct PayloadEditorView: View {
    let payload: AnyPayload
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Payload-specific editor content
                    switch payload.payload {
                    case let wifi as WiFiPayload:
                        WiFiPayloadEditor(payload: wifi)
                    case let vpn as VPNPayload:
                        VPNPayloadEditor(payload: vpn)
                    default:
                        Text("Payload editor not implemented")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Payload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// Basic payload editors
struct WiFiPayloadEditor: View {
    let payload: WiFiPayload
    
    var body: some View {
        Form {
            Section("Network Information") {
                TextField("SSID", text: .constant(payload.SSID_STR))
                Picker("Security", selection: .constant(payload.encryptionType)) {
                    ForEach([WiFiPayload.WiFiEncryption.none, .wep, .wpa, .wpa2, .wpa3], id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            
            Section("Connection") {
                Toggle("Auto Join", isOn: .constant(payload.autoJoin))
                Toggle("Hidden Network", isOn: .constant(payload.hiddenNetwork))
            }
        }
    }
}

struct VPNPayloadEditor: View {
    let payload: VPNPayload
    
    var body: some View {
        Form {
            Section("Server Information") {
                TextField("Server", text: .constant(payload.server))
                Picker("VPN Type", selection: .constant(payload.vpnType)) {
                    ForEach([VPNPayload.VPNType.ikeV2, .l2tp, .ipsec], id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            
            Section("Connection Options") {
                Toggle("Connect On Demand", isOn: .constant(payload.enableOnDemand))
                Toggle("Disconnect On Sleep", isOn: .constant(payload.disconnectOnSleep))
            }
        }
    }
}

// Placeholder views for other sections
struct TemplateListView: View {
    var body: some View {
        List {
            Text("Template functionality coming soon")
                .foregroundColor(.secondary)
        }
    }
}

struct TemplateDetailView: View {
    var body: some View {
        Text("Select a template to view details")
            .foregroundColor(.secondary)
    }
}

struct JAMFStatusView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack {
            ConnectionStatusView(status: appState.isJAMFConnected ? .connected : .disconnected)
            
            if !appState.isJAMFConnected {
                Button("Connect to JAMF Pro") {
                    appState.showJAMFConnection = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

struct JAMFDetailView: View {
    var body: some View {
        Text("JAMF Pro details will appear here")
            .foregroundColor(.secondary)
    }
}

struct SettingsDetailView: View {
    var body: some View {
        Text("Settings details")
            .foregroundColor(.secondary)
    }
}