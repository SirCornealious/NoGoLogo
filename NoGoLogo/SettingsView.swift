import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var xaiKey = ""
    @State private var openaiKey = ""
    @State private var geminiKey = ""
    @State private var showLogs = false
    @EnvironmentObject var logManager: LogManager
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var apiKeys: FetchedResults<APIKey>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
            
            TextField("xAI API Key", text: $xaiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("OpenAI API Key", text: $openaiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Gemini API Key", text: $geminiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
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
            
            Button("View Logs") {
                showLogs = true
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 250)
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
