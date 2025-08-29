import SwiftUI
import AppKit  // For NSApp.terminate

struct DisclaimerSheet: View {
    @Binding var hasAgreed: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button and centered title
            HStack {
                Button(action: {
                    hasAgreed = false
                    NSApp.terminate(nil)
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
                
                Text("Disclaimer")
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
                VStack(spacing: 25) {
                    // Warning Icon and Title
                    VStack(spacing: 15) {
                        Text("⚠️ Disclaimer")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Before using NoGoLogo, please read and understand the following:")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    // Disclaimer Text
                    VStack(alignment: .leading, spacing: 15) {
                        Text("AI Image Generation:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• This app generates images using artificial intelligence")
                            Text("• Generated content may not always be accurate or appropriate")
                            Text("• You are responsible for the prompts you provide")
                            Text("• Generated images should comply with applicable laws and guidelines")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                        
                        Text("API Usage:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• This app requires API keys from xAI, OpenAI, and/or Gemini")
                            Text("• API usage may incur costs depending on your service plan")
                            Text("• You are responsible for managing your own API keys and usage")
                            Text("• API keys are stored locally and securely on your device")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                        
                        Text("Privacy & Security:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Your prompts and API keys are stored locally")
                            Text("• No data is sent to our servers")
                            Text("• Generated images are saved to your Photos library")
                            Text("• Review each AI service's privacy policy for complete information")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    HStack(spacing: 30) {
                        Button(action: {
                            hasAgreed = false
                            NSApp.terminate(nil)
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Decline & Exit")
                            }
                            .font(.headline)
                            .padding()
                            .frame(minWidth: 150)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        
                        Button(action: {
                            hasAgreed = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("I Agree & Continue")
                            }
                            .font(.headline)
                            .padding()
                            .frame(minWidth: 150)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .padding(.vertical, 20)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct DisclaimerSheet_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerSheet(hasAgreed: .constant(false))
    }
}


                
