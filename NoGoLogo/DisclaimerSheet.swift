import SwiftUI
import AppKit  // For NSApp.terminate

struct DisclaimerSheet: View {
    @Binding var hasAgreed: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Disclaimer")
                .font(.title)
                .bold()
            ScrollView {
                Text("""
                Please read and accept this disclaimer before proceeding.

                This application is provided as-is, with no warranty or guarantee of accuracy. By continuing, you agree that you understand and accept any risks, and that the developers are not liable for any consequences resulting from use of this application.

                If you do not agree, please close the application.
                """)
                .font(.body)
                .padding()
            }
            .frame(maxHeight: 240)

            HStack(spacing: 20) {
                Button(action: {
                    hasAgreed = true
                }) {
                    Text("I Agree")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}


                
