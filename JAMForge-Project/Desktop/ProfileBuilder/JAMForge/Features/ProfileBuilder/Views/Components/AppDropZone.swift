import SwiftUI
import UniformTypeIdentifiers

struct AppDropZone: View {
    @ObservedObject var appAnalyzer: AppAnalyzer
    @ObservedObject var profile: ConfigurationProfile
    @State private var isTargeted = false
    @State private var analysisResult: AppAnalysisResult?
    @State private var showingAnalysis = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Drop Zone
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .stroke(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [5])
                )
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "plus.app")
                            .font(.largeTitle)
                            .foregroundColor(isTargeted ? .accentColor : .secondary)
                        
                        Text("Drag macOS Applications Here")
                            .font(.headline)
                            .foregroundColor(isTargeted ? .accentColor : .secondary)
                        
                        Text("Automatically configure required permissions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                }
            
            // Analysis Result
            if let result = analysisResult {
                AppAnalysisCard(result: result, profile: profile)
                    .transition(.slide)
            }
        }
        .animation(.easeInOut, value: isTargeted)
        .animation(.easeInOut, value: analysisResult)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension == "app" else { return }
            
            DispatchQueue.main.async {
                if let result = appAnalyzer.analyzeApp(at: url) {
                    self.analysisResult = result
                    self.showingAnalysis = true
                }
            }
        }
        return true
    }
}
