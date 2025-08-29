import SwiftUI

struct OpenAIModelSettingsView: View {
    @ObservedObject var parameters: OpenAIModelParameters
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
                
                Text("OpenAI Model Settings")
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
                    // Model Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Model:")
                            .font(.headline)
                        
                        Picker("AI Model", selection: $parameters.modelName) {
                            ForEach(OpenAIModelParameters.OpenAIModel.allCases, id: \.self) { model in
                                Text(model.displayName).tag(model.rawValue)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Select the OpenAI model for image generation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Model Information
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Model: \(parameters.modelName)")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("OpenAI's AI image generation model")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Image Size Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image Size:")
                            .font(.headline)
                        
                        Picker("Image Size", selection: $parameters.size) {
                            ForEach(parameters.currentModel.supportedSizes, id: \.self) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Choose the dimensions of generated images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Image Quality Picker (only for GPT Image 1)
                    if parameters.currentModel.supportsQuality {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Image Quality:")
                                .font(.headline)
                            
                            Picker("Image Quality", selection: $parameters.quality) {
                                ForEach(OpenAIModelParameters.ImageQuality.allCases, id: \.self) { quality in
                                    Text(quality.displayName).tag(quality)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Text("Higher quality = better images but slower generation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    }
                    
                    // Image Format Picker (only for GPT Image 1)
                    if parameters.currentModel.supportsFormat {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Image Format:")
                                .font(.headline)
                            
                            Picker("Image Format", selection: $parameters.format) {
                                ForEach(OpenAIModelParameters.ImageFormat.allCases, id: \.self) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Text("Choose the output format for generated images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    }
                    
                    // Background Picker (only for GPT Image 1)
                    if parameters.currentModel.supportsBackground {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Background:")
                                .font(.headline)
                            
                            Picker("Background", selection: $parameters.background) {
                                ForEach(OpenAIModelParameters.Background.allCases, id: \.self) { background in
                                    Text(background.displayName).tag(background)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Text("Choose between opaque or transparent backgrounds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    }
                    
                    // Output Compression (only for GPT Image 1 with JPEG/WebP)
                    if parameters.currentModel.supportsCompression && (parameters.format == .jpeg || parameters.format == .webp) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Output Compression: \(parameters.outputCompression)%")
                                .font(.headline)
                            
                            Slider(value: Binding(
                                get: { Double(parameters.outputCompression) },
                                set: { parameters.outputCompression = Int($0) }
                            ), in: 0...100, step: 5)
                            
                            Text("Lower values = smaller file size, higher values = better quality")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    }
                    
                    // API Endpoint
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Endpoint:")
                            .font(.headline)
                        
                        TextField("Image generation endpoint", text: $parameters.imageGenerationEndpoint)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 12, design: .monospaced))
                        
                        Text("This endpoint is used for OpenAI image generation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        Button("Reset to Defaults") {
                            parameters.size = .auto
                            parameters.quality = .auto
                            parameters.format = .png
                            parameters.background = .opaque
                            parameters.outputCompression = 50
                            parameters.imageGenerationEndpoint = "https://api.openai.com/v1/images/generations"
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
        .frame(minWidth: 550, minHeight: 850)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct OpenAIModelSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAIModelSettingsView(parameters: OpenAIModelParameters())
    }
}


