import Foundation
import Combine

// MARK: - Model Parameters Protocol
protocol ModelParameters: Identifiable, ObservableObject {
    var id: String { get }
}

// MARK: - xAI Model Parameters
class XAIModelParameters: ModelParameters {
    let id = "xai"
    
    @Published var modelName: String = "grok-2-image"
    @Published var numberOfImages: Int = 1
    @Published var responseFormat: ResponseFormat = .b64_json
    @Published var imageGenerationEndpoint: String = "https://api.x.ai/v1/images/generations"
    @Published var chatEndpoint: String = "https://api.x.ai/v1/chat/completions"
    
    // xAI only supports these parameters according to documentation
    enum ResponseFormat: String, CaseIterable {
        case url = "url"
        case b64_json = "b64_json"
        
        var displayName: String {
            switch self {
            case .url:
                return "URL"
            case .b64_json:
                return "Base64 JSON"
            }
        }
    }
    
    init() {}
}

// MARK: - OpenAI Model Parameters
class OpenAIModelParameters: ModelParameters {
    let id = "openai"
    
    @Published var modelName: String = "gpt-image-1"
    @Published var size: ImageSize = .auto
    @Published var quality: ImageQuality = .auto
    @Published var format: ImageFormat = .png
    @Published var background: Background = .opaque
    @Published var outputCompression: Int = 50
    @Published var imageGenerationEndpoint: String = "https://api.openai.com/v1/images/generations"
    
    // Available models with their capabilities
    enum OpenAIModel: String, CaseIterable {
        case gpt_image_1 = "gpt-image-1"
        case dall_e_3 = "dall-e-3"
        case dall_e_2 = "dall-e-2"
        
        var displayName: String {
            switch self {
            case .gpt_image_1:
                return "GPT Image 1 (Latest)"
            case .dall_e_3:
                return "DALL-E 3 (High Quality)"
            case .dall_e_2:
                return "DALL-E 2 (Legacy)"
            }
        }
        
        var supportsQuality: Bool {
            switch self {
            case .gpt_image_1:
                return true
            case .dall_e_3:
                return false
            case .dall_e_2:
                return false
            }
        }
        
        var supportsFormat: Bool {
            switch self {
            case .gpt_image_1:
                return false  // gpt-image-1 doesn't support response_format parameter
            case .dall_e_3:
                return false
            case .dall_e_2:
                return false
            }
        }
        
        var supportsBackground: Bool {
            switch self {
            case .gpt_image_1:
                return true
            case .dall_e_3:
                return false
            case .dall_e_2:
                return false
            }
        }
        
        var supportsCompression: Bool {
            switch self {
            case .gpt_image_1:
                return true
            case .dall_e_3:
                return false
            case .dall_e_2:
                return false
            }
        }
        
        var supportedSizes: [ImageSize] {
            switch self {
            case .gpt_image_1:
                return [.auto, .square, .portrait, .landscape]
            case .dall_e_3:
                return [.auto, .square, .portrait, .landscape]
            case .dall_e_2:
                return [.square] // DALL-E 2 only supports 1024x1024
            }
        }
    }
    
    // Computed property to get the current model
    var currentModel: OpenAIModel {
        return OpenAIModel(rawValue: modelName) ?? .gpt_image_1
    }
    
    enum ImageSize: String, CaseIterable {
        case auto = "auto"
        case square = "1024x1024"
        case portrait = "1024x1536"
        case landscape = "1536x1024"
        
        var displayName: String {
            switch self {
            case .auto:
                return "Auto (1024×1024)"
            case .square:
                return "Square (1024×1024)"
            case .portrait:
                return "Portrait (1024×1536)"
            case .landscape:
                return "Landscape (1536×1024)"
            }
        }
        
        // Helper function to get the actual size value for API calls
        var apiValue: String {
            switch self {
            case .auto:
                return "1024x1024"  // Auto defaults to square size
            case .square:
                return "1024x1024"
            case .portrait:
                return "1024x1536"
            case .landscape:
                return "1536x1024"
            }
        }
    }
    
    enum ImageQuality: String, CaseIterable {
        case auto = "auto"
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .auto:
                return "Auto (Recommended)"
            case .low:
                return "Low (Fastest)"
            case .medium:
                return "Medium (Balanced)"
            case .high:
                return "High (Best Quality)"
            }
        }
    }
    
    enum ImageFormat: String, CaseIterable {
        case png = "png"
        case jpeg = "jpeg"
        case webp = "webp"
        
        var displayName: String {
            switch self {
            case .png:
                return "PNG (Best Quality)"
            case .jpeg:
                return "JPEG (Fastest)"
            case .webp:
                return "WebP (Balanced)"
            }
        }
    }
    
    enum Background: String, CaseIterable {
        case opaque = "opaque"
        case transparent = "transparent"
        
        var displayName: String {
            switch self {
            case .opaque:
                return "Opaque"
            case .transparent:
                return "Transparent"
            }
        }
    }
    
    init() {}
}

// MARK: - Gemini Model Parameters
class GeminiModelParameters: ModelParameters {
    let id = "gemini"
    
    @Published var model: GeminiModel = .gemini_1_5_flash
    @Published var safetySettings: SafetySettings = .block_none
    @Published var baseEndpoint: String = "https://generativelanguage.googleapis.com/v1beta"
    
    enum GeminiModel: String, CaseIterable {
        case gemini_1_5_flash = "gemini-1.5-flash"
        case gemini_1_5_pro = "gemini-1.5-pro"
        case gemini_1_0_pro = "gemini-1.0-pro"
        
        var displayName: String {
            switch self {
            case .gemini_1_5_flash:
                return "Gemini 1.5 Flash (Fastest)"
            case .gemini_1_5_pro:
                return "Gemini 1.5 Pro (Best Quality)"
            case .gemini_1_0_pro:
                return "Gemini 1.0 Pro (Legacy)"
            }
        }
    }
    
    enum SafetySettings: String, CaseIterable {
        case block_none = "BLOCK_NONE"
        case block_low_and_above = "BLOCK_LOW_AND_ABOVE"
        case block_medium_and_above = "BLOCK_MEDIUM_AND_ABOVE"
        case block_high_and_above = "BLOCK_HIGH_AND_ABOVE"
        
        var displayName: String {
            switch self {
            case .block_none:
                return "Allow All Content"
            case .block_low_and_above:
                return "Block Low+ Content"
            case .block_medium_and_above:
                return "Block Medium+ Content"
            case .block_high_and_above:
                return "Block High+ Content"
            }
        }
    }
    
    init() {}
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
