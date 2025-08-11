import SwiftUI
import UniformTypeIdentifiers

struct ProfileDetailView: View {
    @ObservedObject var profile: ConfigurationProfile
    @StateObject private var appAnalyzer = AppAnalyzer()
    @State private var draggedApp: AppAnalysisResult?
    @State private var showingPermissionDetails = false
    @State private var selectedPayload: AnyPayload?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ProfileHeaderView(profile: profile)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Main Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Drag & Drop Zone
                    AppDropZone(appAnalyzer: appAnalyzer, profile: profile)
                        .padding(.horizontal)
                    
                    // Current Payloads
                    PayloadListSection(profile: profile, selectedPayload: $selectedPayload)
                        .padding(.horizontal)
                    
                    // Suggested Configurations
                    if !profile.payloadContent.isEmpty {
                        SuggestedConfigurationsView(profile: profile)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(item: $selectedPayload) { payload in
            PayloadEditorView(payload: payload)
        }
    }
}
