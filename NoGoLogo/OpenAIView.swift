import SwiftUI
import CoreData
import Photos
import UniformTypeIdentifiers
import CoreImage

struct OpenAIView: View {
    let prompt: String
    let numberOfImages: Int
    let apiKey: String
    @Binding var isLoading: Bool
    @Binding var message: String
    @Binding var trigger: UUID
    let parameters: OpenAIModelParameters
    let onCompletion: () -> Void

    
    @State private var generatedImages: [NSImage] = []
    @State private var selectedImage: NSImage? = nil
    @State private var showPopup = false
    @State private var localLoading = false
    
    var body: some View {
        VStack(spacing: 10) {
            Text("OpenAI Images")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            
            if localLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if !generatedImages.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20)], spacing: 20) {
                        ForEach(generatedImages.indices, id: \.self) { index in
                            Image(nsImage: generatedImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .cornerRadius(10)
                                .shadow(color: .white.opacity(0.3), radius: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedImage = generatedImages[index]
                                    showPopup = true
                                }
                                .contextMenu {
                                    ShareLink(item: Image(nsImage: generatedImages[index]), preview: SharePreview("Generated Image", image: Image(nsImage: generatedImages[index])))
                                }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: 300, maxHeight: 400)
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
            } else {
                Text("No images generated yet.")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: 300, maxHeight: 400)
            }
            
            if let selectedImage = selectedImage, showPopup {
                ZStack {
                    Color.black.opacity(0.8)
                        .edgesIgnoringSafeArea(.all)
                    Image(nsImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 600, maxHeight: 400)
                        .cornerRadius(15)
                        .shadow(color: .white.opacity(0.3), radius: 10)
                        .overlay(
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showPopup = false
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                    .padding()
                                }
                                Spacer()
                            }
                        )
                        .contextMenu {
                            ShareLink(item: Image(nsImage: selectedImage), preview: SharePreview("Generated Image", image: Image(nsImage: selectedImage)))
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: 400)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
        .onChange(of: trigger) { oldValue, newValue in
            Task {
                localLoading = true

                
                do {
                    LogManager.shared.log("request", "Fetching images from OpenAI with prompt: \(prompt)")
                    let imagesData = try await fetchImagesFromOpenAI(prompt: prompt, count: numberOfImages, apiKey: apiKey)
                    
                    let savedImages = imagesData.compactMap { NSImage(data: $0) }
                    
                    // Save to Photos album
                    try await saveImagesToPhotosAlbum(imagesData: imagesData)
                    
                    // Update UI
                    await MainActor.run {
                        generatedImages = savedImages
                        message = "OpenAI images saved to Photos/NoGoLogo album!"
                    }
                    LogManager.shared.log("response", "Successfully generated \(savedImages.count) images from OpenAI")
                } catch {
                    await MainActor.run {
                        message = "OpenAI Error: \(error.localizedDescription)"
                    }
                    LogManager.shared.log("error", "OpenAI: \(error.localizedDescription)")
                }
                
                await MainActor.run {
                    localLoading = false
                }
                
                // Notify parent that generation is complete
                onCompletion()

            }
        }
    }
    
    // Async helper for requesting photo authorization - macOS compatible
    func requestPhotoAuthorization() async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .authorized {
            return
        } else if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus == .authorized {
                return
            }
        }
        throw NSError(domain: "PhotosAccessDenied", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])
    }
    
    func saveImagesToPhotosAlbum(imagesData: [Data]) async throws {
        try await requestPhotoAuthorization()
        
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
    
    func fetchImagesFromOpenAI(prompt: String, count: Int, apiKey: String) async throws -> [Data] {
        let startTime = Date()
        let requestId = UUID().uuidString.prefix(8)
        
        LogManager.shared.log("info", "[\(requestId)] OpenAI Image Generation Started")
        LogManager.shared.log("info", "[\(requestId)] Model: \(parameters.modelName)")
        LogManager.shared.log("info", "[\(requestId)] Size: \(parameters.size.rawValue) (API: \(parameters.size.apiValue))")
        LogManager.shared.log("info", "[\(requestId)] Quality: \(parameters.quality.rawValue)")
        LogManager.shared.log("info", "[\(requestId)] Format: \(parameters.format.rawValue)")
        LogManager.shared.log("info", "[\(requestId)] Background: \(parameters.background.rawValue)")
        LogManager.shared.log("info", "[\(requestId)] Prompt: \(prompt)")
        LogManager.shared.log("info", "[\(requestId)] Count: \(count)")
        
        let url = URL(string: parameters.imageGenerationEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        var body: [String: Any] = [
            "prompt": prompt,
            "model": parameters.modelName,
            "n": count,
            "size": parameters.size.apiValue,
            "quality": parameters.quality.rawValue
        ]
        
        // Add conditional parameters based on model capabilities
        if parameters.currentModel.supportsQuality {
            body["quality"] = parameters.quality.rawValue
        }
        if parameters.currentModel.supportsFormat {
            body["response_format"] = "b64_json"
        }
        if parameters.currentModel.supportsBackground {
            body["background"] = parameters.background.rawValue
        }
        if parameters.currentModel.supportsCompression && (parameters.format == .jpeg || parameters.format == .webp) {
            body["output_compression"] = parameters.outputCompression
        }
        
        LogManager.shared.log("info", "[\(requestId)] Request Body: \(body)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            LogManager.shared.log("error", "[\(requestId)] Failed to serialize request body: \(error.localizedDescription)")
            throw error
        }
        
        LogManager.shared.log("info", "[\(requestId)] Sending request to OpenAI...")
        
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
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any] {
                if let message = error["message"] as? String {
                    LogManager.shared.log("error", "[\(requestId)] OpenAI Error Message: \(message)")
                }
                if let type = error["type"] as? String {
                    LogManager.shared.log("error", "[\(requestId)] OpenAI Error Type: \(type)")
                }
                if let code = error["code"] as? String {
                    LogManager.shared.log("error", "[\(requestId)] OpenAI Error Code: \(code)")
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
        
        guard let dataArray = json["data"] as? [[String: Any]] else {
            LogManager.shared.log("error", "[\(requestId)] No 'data' array in response")
            LogManager.shared.log("error", "[\(requestId)] Full response: \(json)")
            throw URLError(.cannotParseResponse)
        }
        
        LogManager.shared.log("info", "[\(requestId)] Found \(dataArray.count) items in data array")
        
        var imagesData: [Data] = []
        for (index, item) in dataArray.enumerated() {
            LogManager.shared.log("info", "[\(requestId)] Processing item \(index + 1), keys: \(Array(item.keys))")
            
            if let b64String = item["b64_json"] as? String {
                LogManager.shared.log("info", "[\(requestId)] Item \(index + 1) has base64 data (length: \(b64String.count))")
                if let imageData = Data(base64Encoded: b64String) {
                    imagesData.append(imageData)
                    LogManager.shared.log("info", "[\(requestId)] Successfully decoded item \(index + 1) to \(imageData.count) bytes")
                } else {
                    LogManager.shared.log("error", "[\(requestId)] Failed to decode base64 data for item \(index + 1)")
                }
            } else if let urlString = item["url"] as? String {
                LogManager.shared.log("info", "[\(requestId)] Item \(index + 1) has URL: \(urlString)")
                // Download image from URL
                do {
                    let imageUrl = URL(string: urlString)!
                    let (imageData, _) = try await URLSession.shared.data(from: imageUrl)
                    imagesData.append(imageData)
                    LogManager.shared.log("info", "[\(requestId)] Successfully downloaded item \(index + 1) from URL to \(imageData.count) bytes")
                } catch {
                    LogManager.shared.log("error", "[\(requestId)] Failed to download image from URL for item \(index + 1): \(error.localizedDescription)")
                }
            } else {
                LogManager.shared.log("warning", "[\(requestId)] Item \(index + 1) has neither b64_json nor url")
            }
        }
        
        if imagesData.isEmpty {
            LogManager.shared.log("error", "[\(requestId)] No valid images found in response")
            LogManager.shared.log("error", "[\(requestId)] Data array contents: \(dataArray)")
            throw URLError(.cannotParseResponse)
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        LogManager.shared.log("info", "[\(requestId)] Successfully generated \(imagesData.count) images in \(String(format: "%.2f", totalTime))s")
        LogManager.shared.log("info", "[\(requestId)] Total image data size: \(imagesData.reduce(0) { $0 + $1.count }) bytes")
        
        return imagesData
    }
}
