import Foundation
import SwiftUI
import Combine

// MARK: - Base Protocol for Model Parameters
protocol ModelParameters: Identifiable, ObservableObject {
    var id: UUID { get }
    var modelName: String { get }
    var displayName: String { get }
}

// MARK: - xAI Model Parameters
class XAIModelParameters: ModelParameters {
    let id = UUID()
    let modelName: String
    let displayName: String
    
    // xAI specific parameters
    @Published var size: ImageSize
    @Published var quality: ImageQuality
    @Published var style: ImageStyle
    
    init(modelName: String = "grok-2-image", displayName: String = "Grok 2 Image") {
        self.modelName = modelName
        self.displayName = displayName
        self.size = .square1024
        self.quality = .standard
        self.style = .natural
    }
    
    enum ImageSize: String, CaseIterable, Codable {
        case square1024 = "1024x1024"
        case square1792 = "1792x1792"
        
        var displayName: String {
            switch self {
            case .square1024: return "1024×1024"
            case .square1792: return "1792×1792"
            }
        }
    }
    
    enum ImageQuality: String, CaseIterable, Codable {
        case standard = "standard"
        case hd = "hd"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .hd: return "HD"
            }
        }
    }
    
    enum ImageStyle: String, CaseIterable, Codable {
        case natural = "natural"
        case vivid = "vivid"
        
        var displayName: String {
            switch self {
            case .natural: return "Natural"
            case .vivid: return "Vivid"
            }
        }
    }
}

// MARK: - OpenAI Model Parameters
class OpenAIModelParameters: ModelParameters {
    let id = UUID()
    let modelName: String
    let displayName: String
    
    // OpenAI specific parameters
    @Published var size: ImageSize
    @Published var quality: ImageQuality
    @Published var style: ImageStyle
    
    init(modelName: String = "dall-e-3", displayName: String = "DALL-E 3") {
        self.modelName = modelName
        self.displayName = displayName
        self.size = .square1024
        self.quality = .standard
        self.style = .natural
    }
    
    enum ImageSize: String, CaseIterable, Codable {
        case square1024 = "1024x1024"
        case square1792 = "1792x1792"
        
        var displayName: String {
            switch self {
            case .square1024: return "1024×1024"
            case .square1792: return "1792×1792"
            }
        }
    }
    
    enum ImageQuality: String, CaseIterable, Codable {
        case standard = "standard"
        case hd = "hd"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .hd: return "HD"
            }
        }
    }
    
    enum ImageStyle: String, CaseIterable, Codable {
        case natural = "natural"
        case vivid = "vivid"
        
        var displayName: String {
            switch self {
            case .natural: return "Natural"
            case .vivid: return "Vivid"
            }
        }
    }
}

// MARK: - Gemini Model Parameters
class GeminiModelParameters: ModelParameters {
    let id = UUID()
    let modelName: String
    let displayName: String
    
    // Gemini specific parameters
    @Published var model: GeminiModel
    @Published var safetySettings: SafetySettings
    
    init(modelName: String = "gemini-1.5-flash-image-preview", displayName: String = "Gemini 1.5 Flash") {
        self.modelName = modelName
        self.displayName = displayName
        self.model = .flash
        self.safetySettings = .balanced
    }
    
    enum GeminiModel: String, CaseIterable, Codable {
        case flash = "gemini-1.5-flash-image-preview"
        case pro = "gemini-1.5-pro"
        
        var displayName: String {
            switch self {
            case .flash: return "Gemini 1.5 Flash"
            case .pro: return "Gemini 1.5 Pro"
            }
        }
    }
    
    enum SafetySettings: String, CaseIterable, Codable {
        case blocked = "blocked"
        case balanced = "balanced"
        case allowed = "allowed"
        
        var displayName: String {
            switch self {
            case .blocked: return "Blocked"
            case .balanced: return "Balanced"
            case .allowed: return "Allowed"
            }
        }
    }
}

// MARK: - Parameter Storage
class ParameterStorage: ObservableObject {
    static let shared = ParameterStorage()
    
    @Published var xaiParameters: XAIModelParameters
    @Published var openaiParameters: OpenAIModelParameters
    @Published var geminiParameters: GeminiModelParameters
    
    private init() {
        // Load from UserDefaults or use defaults
        self.xaiParameters = XAIModelParameters()
        self.openaiParameters = OpenAIModelParameters()
        self.geminiParameters = GeminiModelParameters()
        
        loadParameters()
    }
    
    private func loadParameters() {
        // TODO: Implement loading from UserDefaults
    }
    
    func saveParameters() {
        // TODO: Implement saving to UserDefaults
    }
}
