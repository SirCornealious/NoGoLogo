import SwiftUI

struct OpenAIModelSettingsView: View {
    @ObservedObject var parameters: OpenAIModelParameters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with close button
            HStack {
                Text("OpenAI Model Settings")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Text("×")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            // Model Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Model: \(parameters.displayName)")
                    .font(.headline)
                Text("Model ID: \(parameters.modelName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Divider()
            
            // Image Size
            VStack(alignment: .leading, spacing: 8) {
                Text("Image Size")
                    .font(.headline)
                Picker("Image Size", selection: $parameters.size) {
                    ForEach(OpenAIModelParameters.ImageSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // Image Quality
            VStack(alignment: .leading, spacing: 8) {
                Text("Image Quality")
                    .font(.headline)
                Picker("Image Quality", selection: $parameters.quality) {
                    ForEach(OpenAIModelParameters.ImageQuality.allCases, id: \.self) { quality in
                        Text(quality.displayName).tag(quality)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // Image Style
            VStack(alignment: .leading, spacing: 8) {
                Text("Image Style")
                    .font(.headline)
                Picker("Image Style", selection: $parameters.style) {
                    ForEach(OpenAIModelParameters.ImageStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action Buttons
            HStack {
                Button("Reset to Defaults") {
                    parameters.size = .square1024
                    parameters.quality = .standard
                    parameters.style = .natural
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    ParameterStorage.shared.saveParameters()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct OpenAIModelSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAIModelSettingsView(parameters: OpenAIModelParameters())
    }
}


