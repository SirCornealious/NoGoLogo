import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var xaiKey = ""
    @State private var openaiKey = ""
    @State private var geminiKey = ""
    @State private var showLogs = false
    @State private var showingXAISettings = false
    @State private var showingOpenAISettings = false
    @State private var showingGeminiSettings = false
    @EnvironmentObject var logManager: LogManager
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var apiKeys: FetchedResults<APIKey>
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button and centered title
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Invisible spacer to balance the close button
                Color.clear
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
                .padding(.vertical, 10)
            
            ScrollView {
                VStack(spacing: 20) {
                    // API Key Inputs
                    VStack(spacing: 15) {
                        HStack {
                            TextField("xAI API Key", text: $xaiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Settings") {
                                showingXAISettings = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 20)
                        
                        HStack {
                            TextField("OpenAI API Key", text: $openaiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Settings") {
                                showingOpenAISettings = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 20)
                        
                        HStack {
                            TextField("Gemini API Key", text: $geminiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Settings") {
                                showingGeminiSettings = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Save Button
                    Button(action: {
                        saveAPIKeys()
                        dismiss()
                    }) {
                        Text("Save API Keys")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(xaiKey.isEmpty && openaiKey.isEmpty && geminiKey.isEmpty)
                    .padding(.horizontal, 20)
                    
                    // View Logs Button
                    Button("View Logs") {
                        showLogs = true
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            for key in apiKeys {
                switch key.type {
                case "xai":
                    xaiKey = key.key ?? ""
                case "openai":
                    openaiKey = key.key ?? ""
                case "gemini":
                    geminiKey = key.key ?? ""
                default:
                    break
                }
            }
        }
        .sheet(isPresented: $showLogs) {
            LogViewerSheet(showingSheet: $showLogs)
                .environmentObject(logManager)
        }
        .sheet(isPresented: $showingXAISettings) {
            XAIModelSettingsView(parameters: ParameterStorage.shared.xaiParameters)
        }
        .sheet(isPresented: $showingOpenAISettings) {
            OpenAIModelSettingsView(parameters: ParameterStorage.shared.openaiParameters)
        }
        .sheet(isPresented: $showingGeminiSettings) {
            GeminiModelSettingsView(parameters: ParameterStorage.shared.geminiParameters)
        }
    }
    
    private func saveAPIKeys() {
        // Delete existing keys
        apiKeys.forEach { viewContext.delete($0) }
        
        // Save new keys if not empty
        if !xaiKey.isEmpty {
            let newKey = APIKey(context: viewContext)
            newKey.type = "xai"
            newKey.key = xaiKey
        }
        if !openaiKey.isEmpty {
            let newKey = APIKey(context: viewContext)
            newKey.type = "openai"
            newKey.key = openaiKey
        }
        if !geminiKey.isEmpty {
            let newKey = APIKey(context: viewContext)
            newKey.type = "gemini"
            newKey.key = geminiKey
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(LogManager.shared)
    }
}
