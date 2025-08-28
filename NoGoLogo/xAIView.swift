import SwiftUI
import CoreData
import Photos
import UniformTypeIdentifiers
import CoreImage

struct XAIView: View {
    let prompt: String
    let numberOfImages: Int
    let apiKey: String
    @Binding var isLoading: Bool
    @Binding var message: String
    @Binding var trigger: UUID
    @State private var generatedImages: [NSImage] = []
    @State private var selectedImage: NSImage? = nil
    @State private var showPopup = false
    @State private var localLoading = false
    
    var body: some View {
        VStack(spacing: 10) {
            Text("xAI Images")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            
            if localLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
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
        .frame(maxWidth: 300)
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(15)
        .onChange(of: trigger) { _ in
            Task {
                localLoading = true
                do {
                    LogManager.shared.log("request", "Fetching images from xAI with prompt: \(prompt)")
                    let imagesData = try await fetchImagesFromXAI(prompt: prompt, count: numberOfImages, apiKey: apiKey)
                    
                    // Crop bottom 20 pixels for xAI (potential watermark)
                    let croppedData = imagesData.compactMap { cropBottomOfImage(imageData: $0, pixelsToCrop: 20) }
                    
                    let savedImages = croppedData.compactMap { NSImage(data: $0) }
                    
                    // Save to Photos album
                    try await saveImagesToPhotosAlbum(imagesData: croppedData)
                    
                    // Update UI
                    generatedImages = savedImages
                    message = "xAI images saved to Photos/NoGoLogo album!"
                    LogManager.shared.log("response", "Successfully generated \(savedImages.count) images from xAI")
                } catch {
                    message = "xAI Error: \(error.localizedDescription)"
                    LogManager.shared.log("error", "xAI: \(error.localizedDescription)")
                }
                localLoading = false
                isLoading = false  // Approximate; last API sets it
            }
        }
    }
    
    // Helper function to crop bottom pixels
    func cropBottomOfImage(imageData: Data, pixelsToCrop: CGFloat) -> Data? {
        guard let ciImage = CIImage(data: imageData) else { return nil }
        let originalRect = ciImage.extent
        let croppedRect = CGRect(x: 0, y: pixelsToCrop, width: originalRect.width, height: originalRect.height - pixelsToCrop)
        let croppedImage = ciImage.cropped(to: croppedRect)
        let context = CIContext()
        guard let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent) else { return nil }
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: croppedRect.width, height: croppedRect.height))
        guard let jpegData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: jpegData) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [:])
    }
    
    // Async helper for requesting photo authorization
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
        throw NSError(domain: "PhotosAccessDenied", code: 0, userInfo: nil)
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
                    continuation.resume(throwing: NSError(domain: "UnknownError", code: 0, userInfo: nil))
                }
            }
        }
    }
    
    func fetchImagesFromXAI(prompt: String, count: Int, apiKey: String) async throws -> [Data] {
        let url = URL(string: "https://api.x.ai/v1/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt,
            "model": "grok-2-image",
            "n": count,
            "response_format": "b64_json"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let imageDataArray = json?["data"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        
        var images: [Data] = []
        for imageDict in imageDataArray {
            guard let base64String = imageDict["b64_json"] as? String,
                  let imageData = Data(base64Encoded: base64String) else {
                throw URLError(.cannotParseResponse)
            }
            images.append(imageData)
        }
        
        return images
    }
}
