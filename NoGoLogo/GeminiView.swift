import SwiftUI
import CoreData
import Photos
import UniformTypeIdentifiers
import CoreImage

struct GeminiView: View {
    let prompt: String
    let numberOfImages: Int
    let apiKey: String
    @Binding var isLoading: Bool
    @Binding var message: String
    @Binding var trigger: UUID
    let parameters: GeminiModelParameters
    let onCompletion: () -> Void

    
    @State private var generatedImages: [NSImage] = []
    @State private var selectedImage: NSImage? = nil
    @State private var showPopup = false
    @State private var localLoading = false
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Gemini Images")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.green)
            
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
        .background(Color.green.opacity(0.1))
        .cornerRadius(15)
        .onChange(of: trigger) { oldValue, newValue in
            Task {
                localLoading = true

                
                do {
                    LogManager.shared.log("request", "Fetching images from Gemini with prompt: \(prompt)")
                    let imagesData = try await fetchImagesFromGemini(prompt: prompt, count: numberOfImages, apiKey: apiKey)
                    
                    let savedImages = imagesData.compactMap { NSImage(data: $0) }
                    
                    // Save to Photos album
                    try await saveImagesToPhotosAlbum(imagesData: imagesData)
                    
                    // Update UI
                    await MainActor.run {
                        generatedImages = savedImages
                        message = "Gemini images saved to Photos/NoGoLogo album!"
                    }
                    LogManager.shared.log("response", "Successfully generated \(savedImages.count) images from Gemini")
                } catch {
                    await MainActor.run {
                        message = "Gemini Error: \(error.localizedDescription)"
                    }
                    LogManager.shared.log("error", "Gemini: \(error.localizedDescription)")
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
    
    func fetchImagesFromGemini(prompt: String, count: Int, apiKey: String) async throws -> [Data] {
        // Gemini doesn't support image generation - it's a text model only
        LogManager.shared.log("error", "Gemini API: Image generation not supported - Gemini is a text-only model")
        throw NSError(domain: "GeminiAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Gemini doesn't support image generation. It's a text-only AI model. Please use xAI or OpenAI for image generation."])
    }
}
