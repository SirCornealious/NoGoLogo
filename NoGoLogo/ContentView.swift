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
    @StateObject private var parameterStorage = ParameterStorage.shared
   
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
        .onChange(of: selectedAPIs) { oldValue, newValue in
            selectedAPIsString = Array(newValue).joined(separator: ",")
        }

    }
   
    private var headerView: some View {
        Text("NoGoLogo Image Generator")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 30)
    }
   
    private var promptSection: some View {
        HStack {
            ZStack(alignment: .leading) {
                if prompt.isEmpty {
                    Text("Enter image prompt (e.g., 'A cat in a tree')")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.leading, 16)
                }
                
                TextField("", text: $prompt)
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
                    .accentColor(.white)
            }
            
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
            Spacer()
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.gray.opacity(0.7))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 40)
    }
   
    private var numberPicker: some View {
        HStack {
            Text("Number of images:")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Menu {
                ForEach(1...10, id: \.self) { num in
                    Button(action: {
                        numberOfImages = num
                    }) {
                        HStack {
                            Text("\(num)")
                            if numberOfImages == num {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("\(numberOfImages)")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
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
                XAIView(prompt: prompt, numberOfImages: numberOfImages, apiKey: apiKey, isLoading: $isLoading, message: $message, trigger: $generateTrigger, parameters: parameterStorage.xaiParameters, onCompletion: {
                    isLoading = false
                })
            }
            if selectedAPIs.contains("openai"), let apiKey = apiKeys.first(where: { $0.type == "openai" })?.key {
                OpenAIView(prompt: prompt, numberOfImages: numberOfImages, apiKey: apiKey, isLoading: $isLoading, message: $message, trigger: $generateTrigger, parameters: parameterStorage.openaiParameters, onCompletion: {
                    isLoading = false
                })
            }
            if selectedAPIs.contains("gemini"), let apiKey = apiKeys.first(where: { $0.type == "gemini" })?.key {
                GeminiView(prompt: prompt, numberOfImages: numberOfImages, apiKey: apiKey, isLoading: $isLoading, message: $message, trigger: $generateTrigger, parameters: parameterStorage.geminiParameters, onCompletion: {
                    isLoading = false
                })
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
        message = "Grokifying your prompt..."
        Task {
            do {
                let refined = try await refinePromptWithGrok(prompt: prompt)
                prompt = refined
                message = "Prompt Grokified! ✨"
                LogManager.shared.log("info", "Prompt Grokified: '\(refined)'")
            } catch {
                // Whimsical fallback with random creative elements
                let creativeElements = [
                    "with floating bubbles and rainbow sparkles",
                    "in steampunk style with gears and steam",
                    "as a cyberpunk neon dreamscape",
                    "with magical floating crystals and fairy dust",
                    "in watercolor with splashes of vibrant colors",
                    "as a retro-futuristic hologram",
                    "with ethereal glowing effects and mist",
                    "in pop art style with bold comic colors",
                    "with surreal dreamlike atmosphere",
                    "as a whimsical cartoon with exaggerated features"
                ]
                let randomElement = creativeElements.randomElement() ?? ""
                prompt = prompt.replacingOccurrences(of: "A detailed and vivid version of:", with: "") // Remove previous fallback if present
                prompt = "\(prompt), \(randomElement)"
                message = "Prompt Grokified (whimsical fallback mode)! ✨"
                LogManager.shared.log("info", "Prompt Grokified (fallback): '\(prompt)'")
                LogManager.shared.log("warning", "Grok API failed, using fallback: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    // MARK: - Photo Saving
    private func saveImagesToPhotosAlbum(imagesData: [Data]) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .authorized {
            // Already authorized
        } else if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus != .authorized {
                throw NSError(domain: "PhotosAccessDenied", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])
            }
        } else {
            throw NSError(domain: "PhotosAccessDenied", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])
        }
        
        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let albumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "NoGoLogo")
                for imageData in imagesData {
                    let assetRequest = PHAssetCreationRequest.forAsset()
                    assetRequest.addResource(with: .photo, data: imageData, options: nil)
                    albumRequest.addAssets([assetRequest.placeholderForCreatedAsset!] as NSArray)
                }
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: NSError(domain: "UnknownError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred while saving to Photos"]))
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func refinePromptWithGrok(prompt: String) async throws -> String {
        let startTime = Date()
        let requestId = UUID().uuidString.prefix(8)
        
        LogManager.shared.log("info", "[\(requestId)] Grokify Started")
        LogManager.shared.log("info", "[\(requestId)] Original prompt: '\(prompt)'")
        LogManager.shared.log("info", "[\(requestId)] Endpoint: \(parameterStorage.xaiParameters.chatEndpoint)")
        
        guard let apiKey = apiKeys.first(where: { $0.type == "xai" })?.key else {
            LogManager.shared.log("error", "[\(requestId)] No xAI API key found for Grokify")
            throw NSError(domain: "No API Key", code: 0, userInfo: nil)
        }
        
        LogManager.shared.log("info", "[\(requestId)] API key found (length: \(apiKey.count))")
        
        let url = URL(string: parameterStorage.xaiParameters.chatEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let body: [String: Any] = [
            "model": "grok-3-mini",
            "messages": [
                ["role": "system", "content": "You are a creative prompt enhancer. Take the user's prompt and make it more whimsical, artistic, and fun by adding random art styles, creative elements, or unexpected twists. Be concise and creative - no explanations, just the enhanced prompt. Examples: 'A cat in a tree' becomes 'A cyberpunk cat in a neon tree with floating bubbles and rainbow sparkles' or 'A cat in a tree' becomes 'A steampunk cat in a mechanical tree with gears and steam, painted in watercolor style'"],
                ["role": "user", "content": "Make this prompt more creative and whimsical: \(prompt)"]
            ]
        ]
        
        LogManager.shared.log("info", "[\(requestId)] Request body: \(body)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            LogManager.shared.log("error", "[\(requestId)] Failed to serialize request body: \(error.localizedDescription)")
            throw error
        }
        
        LogManager.shared.log("info", "[\(requestId)] Sending request to Grok API...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let responseTime = Date().timeIntervalSince(startTime)
        LogManager.shared.log("info", "[\(requestId)] Response received in \(String(format: "%.2f", responseTime))s")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            LogManager.shared.log("error", "[\(requestId)] Invalid response type: \(type(of: response))")
            throw URLError(.badServerResponse)
        }
        
        LogManager.shared.log("info", "[\(requestId)] HTTP Status: \(httpResponse.statusCode)")
        LogManager.shared.log("info", "[\(requestId)] Response Headers: \(httpResponse.allHeaderFields)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            LogManager.shared.log("error", "[\(requestId)] HTTP \(httpResponse.statusCode) Error")
            LogManager.shared.log("error", "[\(requestId)] Response Body: \(responseString)")
            
            // Try to parse error details
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                LogManager.shared.log("error", "[\(requestId)] Error response JSON: \(errorJson)")
                
                if let error = errorJson["error"] as? [String: Any] {
                    if let message = error["message"] as? String {
                        LogManager.shared.log("error", "[\(requestId)] Grok Error Message: \(message)")
                    }
                    if let type = error["type"] as? String {
                        LogManager.shared.log("error", "[\(requestId)] Grok Error Type: \(type)")
                    }
                    if let code = error["code"] as? String {
                        LogManager.shared.log("error", "[\(requestId)] Grok Error Code: \(code)")
                    }
                }
            }
            
            throw URLError(.badServerResponse)
        }
        
        LogManager.shared.log("info", "[\(requestId)] Successfully received response")
        
        let json: [String: Any]
        do {
            json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        } catch {
            LogManager.shared.log("error", "[\(requestId)] Failed to parse JSON response: \(error.localizedDescription)")
            LogManager.shared.log("error", "[\(requestId)] Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw URLError(.cannotParseResponse)
        }
        
        LogManager.shared.log("info", "[\(requestId)] Response JSON keys: \(Array(json.keys))")
        
        guard let choices = json["choices"] as? [[String: Any]] else {
            LogManager.shared.log("error", "[\(requestId)] No 'choices' array in response")
            LogManager.shared.log("error", "[\(requestId)] Full response: \(json)")
            throw URLError(.cannotParseResponse)
        }
        
        LogManager.shared.log("info", "[\(requestId)] Found \(choices.count) choices in response")
        
        guard let message = choices.first?["message"] as? [String: Any] else {
            LogManager.shared.log("error", "[\(requestId)] No 'message' in first choice")
            LogManager.shared.log("error", "[\(requestId)] First choice: \(choices.first ?? [:])")
            throw URLError(.cannotParseResponse)
        }
        
        LogManager.shared.log("info", "[\(requestId)] Message keys: \(Array(message.keys))")
        
        guard let content = message["content"] as? String else {
            LogManager.shared.log("error", "[\(requestId)] No 'content' in message")
            LogManager.shared.log("error", "[\(requestId)] Message: \(message)")
            throw URLError(.cannotParseResponse)
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        LogManager.shared.log("info", "[\(requestId)] Successfully Grokified prompt in \(String(format: "%.2f", totalTime))s")
        LogManager.shared.log("info", "[\(requestId)] Original: '\(prompt)'")
        LogManager.shared.log("info", "[\(requestId)] Enhanced: '\(content)'")
        
        return content
    }
}
struct ApiTogglesView: View {
    let apiKeys: FetchedResults<APIKey>
    @Binding var selectedAPIs: Set<String>
   
    var body: some View {
        HStack {
            ForEach(apiKeys.map { $0.type ?? "" }.uniqued(), id: \.self) { apiType in
                Toggle(getDisplayName(for: apiType), isOn: Binding(
                    get: { selectedAPIs.contains(apiType) },
                    set: { if $0 { selectedAPIs.insert(apiType) } else { selectedAPIs.remove(apiType) } }
                ))
                .toggleStyle(SwitchToggleStyle(tint: getColor(for: apiType)))
                .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private func getDisplayName(for apiType: String) -> String {
        switch apiType.lowercased() {
        case "xai":
            return "xAI (Grok-2-Image)"
        case "openai":
            return "OpenAI (GPT Image)"
        case "gemini":
            return "Gemini"
        default:
            return apiType.uppercased()
        }
    }
    
    private func getColor(for apiType: String) -> Color {
        switch apiType.lowercased() {
        case "xai":
            return .gray
        case "openai":
            return .gray
        case "gemini":
            return .gray
        default:
            return .gray
        }
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
