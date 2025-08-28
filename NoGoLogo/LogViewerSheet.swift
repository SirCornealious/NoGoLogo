import SwiftUI
import UniformTypeIdentifiers

struct LogViewerSheet: View {
    @EnvironmentObject var logManager: LogManager
    @Binding var showingSheet: Bool
    @State private var showExportPanel = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { showingSheet = false }) {
                    Circle()
                        .foregroundColor(.red)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.black.opacity(0.1)))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 4)
                Spacer()
            }
            .padding(.top, 8)
            
            Text("API Request/Response Log")
                .font(.headline)
                .padding(.bottom, 6)
            
            ScrollView {
                Text(logManager.formattedLogText())
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding([.leading, .trailing, .bottom], 8)
            }
            .frame(minHeight: 200, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            
            HStack {
                Button("Copy") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(logManager.formattedLogText(), forType: .string)
                }
                Button("Export...") {
                    showExportPanel = true
                }
                Button("Clear Log") {
                    logManager.clear()
                }
                Spacer()
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 420)
        .fileExporter(
            isPresented: $showExportPanel,
            document: LogFileDocument(logManager.formattedLogText()),
            contentType: .plainText,
            defaultFilename: "NoGoLogo_API_Log.txt"
        ) { _ in }
    }
}

struct LogFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String

    init(_ text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let str = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = str
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
