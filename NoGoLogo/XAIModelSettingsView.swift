import SwiftUI

struct XAIModelSettingsView: View {
    @ObservedObject var parameters: XAIModelParameters
    @Environment(\.dismiss) private var dismiss
    
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
                
                Text("xAI Model Settings")
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
                    // Model Information
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Model: \(parameters.modelName)")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        Text("xAI's Grok-2-Image model for AI image generation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Response Format Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response Format:")
                            .font(.headline)
                        
                        Picker("Response Format", selection: $parameters.responseFormat) {
                            ForEach(XAIModelParameters.ResponseFormat.allCases, id: \.self) { format in
                                Text(format.displayName).tag(format)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text("Choose how images are returned: URL links or base64 encoded data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Number of Images Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of Images:")
                            .font(.headline)
                        
                        Text("\(parameters.numberOfImages) image(s)")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("Note: Number of images is controlled from the main interface")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // API Limitations Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Limitations:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Only supports 1-10 images per request")
                            Text("• No size customization (fixed output)")
                            Text("• No quality settings")
                            Text("• No style options")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // API Endpoints
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Endpoints:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Image Generation:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Image generation endpoint", text: $parameters.imageGenerationEndpoint)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 12, design: .monospaced))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Chat Completions:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Chat completions endpoint", text: $parameters.chatEndpoint)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 12, design: .monospaced))
                            }
                        }
                        
                        Text("These endpoints are used for image generation and prompt enhancement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        Button("Reset to Defaults") {
                            parameters.responseFormat = .b64_json
                            parameters.imageGenerationEndpoint = "https://api.x.ai/v1/images/generations"
                            parameters.chatEndpoint = "https://api.x.ai/v1/chat/completions"
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .padding(.vertical, 20)
            }
        }
        .frame(minWidth: 450, minHeight: 750)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct XAIModelSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        XAIModelSettingsView(parameters: XAIModelParameters())
    }
}


