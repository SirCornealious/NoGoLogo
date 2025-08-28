import SwiftUI
import CoreData
import Photos
import UniformTypeIdentifiers
import CoreImage
import AppKit // For NSApp.terminate in disclaimer
struct ContentView: View {
    @State private var prompt = ""
    @State private var message = "Enter a prompt and generate images."
    @State private var isLoading = false
    @State private var numberOfImages = 1
    @State private var showingSettings = false
    @State private var generateTrigger = UUID()
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var logManager: LogManager
   
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var apiKeys: FetchedResults<APIKey>
   
    @AppStorage("selectedAPIs") private var selectedAPIsString = ""
    @State private var selectedAPIs: Set<String> = []
   
    @AppStorage("hasAgreedToDisclaimer") private var hasAgreed = false
   
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
           
            VStack(spacing: 20) {
                headerView
                promptSection
                selectorsSection
                generateButton
                apiViewsSection
                footerSection
            }
        }
        .frame(
            minWidth: CGFloat(max(400, selectedAPIs.count * 400)),
            idealWidth: CGFloat(max(600, selectedAPIs.count * 600)),
            minHeight: 700,
            idealHeight: 900
        )
        .sheet(isPresented: Binding<Bool>(
            get: { !hasAgreed },
            set: { _ in }
        )) {
            DisclaimerSheet(hasAgreed: $hasAgreed)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(logManager)
        }
        .onAppear {
            // Load from storage
            selectedAPIs = Set(selectedAPIsString.components(separatedBy: ",").filter { !$0.isEmpty })
           
            // Pre-select if empty
            let types = apiKeys.map { $0.type ?? "" }
            if selectedAPIs.isEmpty && !types.isEmpty {
                selectedAPIs = Set(types.uniqued())
            }
        }
        .onChange(of: selectedAPIs) { _ in
            selectedAPIsString = Array(selectedAPIs).joined(separator: ",")
        }
        .overlay(
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(Color.gray.opacity(0.5))
            .clipShape(Circle())
            .position(x: 40, y: (NSScreen.main?.frame.height ?? 800) - 40) // Bottom left
        )
    }
   
    private var headerView: some View {
        Text("NoGoLogo Image Generator")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 30)
    }
   
    private var promptSection: some View {
        HStack {
            TextField("Enter image prompt (e.g., 'A cat in a tree')", text: $prompt)
                .font(.system(size: 16, design: .rounded))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(16)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 2)
           
            Button(action: {
                grokifyPrompt()
            }) {
                Text("Grokify")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .disabled(isLoading || prompt.isEmpty)
        }
        .padding(.horizontal, 40)
    }
   
    private var selectorsSection: some View {
        HStack {
            numberPicker
            if !apiKeys.isEmpty {
                ApiTogglesView(apiKeys: apiKeys, selectedAPIs: $selectedAPIs)
            }
        }
        .padding(.horizontal, 40)
    }
   
    private var numberPicker: some View {
        HStack {
            Text("Number of images:")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            Picker("", selection: $numberOfImages) {
                ForEach(1...10, id: \.self) { num in
                    Text("\(num)").tag(num)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 150)
            .tint(.white) // For contrast
        }
    }
   
    private var generateButton: some View {
        Button(action: {
            generateAndSaveImages()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isLoading ? "Generating..." : "Generate & Save Images")
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .padding()
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading || prompt.isEmpty || apiKeys.isEmpty)
        .padding(.horizontal, 40)
    }
   
    private var apiViewsSection: some View {
        HStack(spacing: 20) {
            if selectedAPIs.contains("xai"), let apiKey = apiKeys.first(where: { $0.type == "xai" })?.key {
                XAIView(prompt: prompt, numberOfImages: numberOfImages, apiKey: apiKey, isLoading: $isLoading, message: $message, trigger: $generateTrigger)
            }
            if selectedAPIs.contains("openai"), let apiKey = apiKeys.first(where: { $0.type == "openai" })?.key {
                OpenAIView(prompt: prompt, numberOfImages: numberOfImages, apiKey: apiKey, isLoading: $isLoading, message: $message, trigger: $generateTrigger)
            }
            if selectedAPIs.contains("gemini"), let apiKey = apiKeys.first(where: { $0.type == "gemini" })?.key {
                GeminiView(prompt: prompt, numberOfImages: numberOfImages, apiKey: apiKey, isLoading: $isLoading, message: $message, trigger: $generateTrigger)
            }
        }
        .frame(maxHeight: 400)
        .padding(.horizontal, 40)
    }
   
    private var footerSection: some View {
        VStack(spacing: 10) {
            Text(message)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(message.contains("Error") ? .red : .green)
                .padding(.horizontal, 40)
        }
    }
   
    func generateAndSaveImages() {
        isLoading = true
        message = "Generating images..."
        generateTrigger = UUID() // Triggers .onChange in child views
    }
   
    func grokifyPrompt() {
        isLoading = true
        Task {
            do {
                let refined = try await refinePromptWithGrok(prompt: prompt)
                prompt = refined
                message = "Prompt Grokified!"
            } catch {
                // Randomized fallback
                let styles = [
                    "in cyberpunk neon glow",
                    "as a surreal dreamscape",
                    "with epic fantasy vibes",
                    "in high-contrast black and white",
                    "like a vintage poster",
                    "in vibrant watercolor",
                    "with futuristic sci-fi elements",
                    "as a cute cartoon illustration",
                    "in realistic photographic detail",
                    "with magical realism touch"
                ]
                let randomStyle = styles.randomElement() ?? ""
                prompt = prompt.replacingOccurrences(of: "A detailed and vivid version of:", with: "") // Remove previous fallback if present
                prompt = "A detailed and vivid version of: \(prompt), \(randomStyle)"
                message = "Prompt Grokified (fallback mode): \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
   
    func refinePromptWithGrok(prompt: String) async throws -> String {
        guard let apiKey = apiKeys.first(where: { $0.type == "xai" })?.key else {
            throw NSError(domain: "No API Key", code: 0, userInfo: nil)
        }
       
        let url = URL(string: "https://api.x.ai/v1/chat/completions")! // Assuming xAI chat endpoint; check https://x.ai/api if different
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
       
        let body: [String: Any] = [
            "model": "grok-3-mini",
            "messages": [
                ["role": "system", "content": "You are a helpful prompt refiner for image generation. Make the user's prompt more detailed, creative, and optimized for AI image models."],
                ["role": "user", "content": "Refine this image prompt: \(prompt)"]
            ]
        ]
       
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
       
        let (data, response) = try await URLSession.shared.data(for: request)
       
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
       
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw URLError(.cannotParseResponse)
        }
       
        return content
    }
}
struct ApiTogglesView: View {
    let apiKeys: FetchedResults<APIKey>
    @Binding var selectedAPIs: Set<String>
   
    var body: some View {
        HStack {
            ForEach(apiKeys.map { $0.type ?? "" }.uniqued(), id: \.self) { apiType in
                Toggle(apiType.uppercased(), isOn: Binding(
                    get: { selectedAPIs.contains(apiType) },
                    set: { if $0 { selectedAPIs.insert(apiType) } else { selectedAPIs.remove(apiType) } }
                ))
                .toggleStyle(SwitchToggleStyle(tint: apiType == "xai" ? .purple : apiType == "openai" ? .blue : .green))
            }
        }
        .padding(.horizontal, 40)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(LogManager.shared)
    }
}
// Extension for uniqued (from original)
extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
