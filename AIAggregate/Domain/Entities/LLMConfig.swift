import Foundation

struct LLMProvider: Identifiable, Equatable, Codable, Sendable, Hashable {
    var id: String { name }
    let name: String
    let defaultBaseURL: String
    let defaultModel: String
    let placeholderKey: String

    static let builtin: [LLMProvider] = [
        LLMProvider(
            name: "自定义模型",
            defaultBaseURL: "https://api.example.com/v1",
            defaultModel: "gpt-4o-mini",
            placeholderKey: "custom_api_key"
        )
    ]
}

struct LLMConfig: Equatable, Codable, Sendable {
    var displayName: String
    var baseURL: String
    var apiKey: String
    var modelName: String
    var modelID: String
    var protocolType: String
    var apiPath: String?
    var temperature: Double
    var maxTokens: Int
}
