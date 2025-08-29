import SwiftUI

struct GeminiModelSettingsView: View {
    @ObservedObject var parameters: GeminiModelParameters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with close button
            HStack {
                Text("Gemini Model Settings")
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
            
            // Model Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Model Version")
                    .font(.headline)
                Picker("Model Version", selection: $parameters.model) {
                    ForEach(GeminiModelParameters.GeminiModel.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // Safety Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Safety Settings")
                    .font(.headline)
                Picker("Safety Settings", selection: $parameters.safetySettings) {
                    ForEach(GeminiModelParameters.SafetySettings.allCases, id: \.self) { safety in
                        Text(safety.displayName).tag(safety)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // Safety Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Safety Information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("• Blocked: Strictest content filtering")
                Text("• Balanced: Moderate content filtering")
                Text("• Allowed: Minimal content filtering")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Spacer()
            
            // Action Buttons
            HStack {
                Button("Reset to Defaults") {
                    parameters.model = .flash
                    parameters.safetySettings = .balanced
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

struct GeminiModelSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeminiModelSettingsView(parameters: GeminiModelParameters())
    }
}


