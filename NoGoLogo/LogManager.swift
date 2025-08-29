import Foundation
import SwiftUI

struct LogEntry: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let type: String  // "request", "response", "error", etc.
    let message: String
}

@MainActor
final class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published private(set) var logs: [LogEntry] = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    func log(_ type: String, _ message: String) {
        let entry = LogEntry(date: Date(), type: type, message: message)
        logs.append(entry)
    }
    
    func clear() {
        logs.removeAll()
    }
    
    func formattedLogText() -> String {
        logs.map { "[\($0.type.uppercased())] \(dateFormatter.string(from: $0.date)): \($0.message)" }
            .joined(separator: "\n\n")
    }
}
