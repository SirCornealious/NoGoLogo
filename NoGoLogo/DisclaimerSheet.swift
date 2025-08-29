import SwiftUI
import AppKit  // For NSApp.terminate

struct DisclaimerSheet: View {
    @Binding var hasAgreed: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("⚠️ Disclaimer")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.orange)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Please read and accept this disclaimer before proceeding.")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("""
                    This application is provided as-is, with no warranty or guarantee of accuracy. By continuing, you agree that you understand and accept any risks, and that the developers are not liable for any consequences resulting from use of this application.
                    
                    The app will generate images using AI services and save them to your Photos library. Please ensure you have proper permissions and understand the terms of service for any AI services you use.
                    
                    If you do not agree, please close the application.
                    """)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
            }
            .frame(maxHeight: 300)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            HStack(spacing: 20) {
                Button(action: {
                    hasAgreed = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("I Agree")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
                }
                
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Decline")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
                }
            }
            .padding(.horizontal)
        }
        .padding(30)
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct DisclaimerSheet_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerSheet(hasAgreed: .constant(false))
    }
}


                
