import SwiftUI

struct GeminiModelSettingsView: View {
    @ObservedObject var parameters: GeminiModelParameters
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
                
                Text("Gemini Model Settings")
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
                        Text("Model: \(parameters.model.displayName)")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Google's Gemini model for AI image generation and analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Model Version Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Model Version:")
                            .font(.headline)
                        
                        Picker("Model Version", selection: $parameters.model) {
                            ForEach(GeminiModelParameters.GeminiModel.allCases, id: \.self) { model in
                                Text(model.displayName).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Choose the Gemini model version for image generation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Safety Settings Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Safety Settings:")
                            .font(.headline)
                        
                        Picker("Safety Settings", selection: $parameters.safetySettings) {
                            ForEach(GeminiModelParameters.SafetySettings.allCases, id: \.self) { setting in
                                Text(setting.displayName).tag(setting)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Control content filtering and safety thresholds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Safety Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Safety Information:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• BLOCK_NONE: Allow all content")
                            Text("• BLOCK_LOW_AND_ABOVE: Block potentially harmful content")
                            Text("• BLOCK_MEDIUM_AND_ABOVE: Moderate filtering")
                            Text("• BLOCK_HIGH_AND_ABOVE: Strict filtering")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // API Capabilities Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Capabilities:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠️ Text-only model - NO image generation")
                            Text("• Advanced text understanding and generation")
                            Text("• Multiple model versions available")
                            Text("• Configurable safety settings")
                            Text("• High-quality text output")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // API Endpoint
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Endpoint:")
                            .font(.headline)
                        
                        TextField("Base API endpoint", text: $parameters.baseEndpoint)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                                                .font(.system(size: 12, design: .monospaced))
                        
                        Text("This is the base endpoint for Gemini API calls")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        Button("Reset to Defaults") {
                            parameters.model = .gemini_1_5_flash
                            parameters.safetySettings = .block_none
                            parameters.baseEndpoint = "https://generativelanguage.googleapis.com/v1beta"
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
        .frame(minWidth: 450, minHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct GeminiModelSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeminiModelSettingsView(parameters: GeminiModelParameters())
    }
}


